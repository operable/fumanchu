defmodule FuManchu.Lexer do
  alias FuManchu.Lexer.TokenMissingError
  alias FuManchu.Lexer.TokenUnexpectedError
  require Logger

  @type line :: pos_integer
  @type column :: non_neg_integer
  @type token :: {Atom, String.t, line, column}
  @type tokens :: [token, ...]

  @spec scan(String.t | char_list) :: {:ok, tokens} | {:error, any}
  def scan(bin) when is_binary(bin) do
    scan(String.to_char_list(bin))
  end

  def scan(char_list) do
    case scan(char_list, [], [], 1, 0) do
      {:error, error} ->
        {:error, error}
      tokens ->
        {:ok, tokens}
    end
  end

  defp scan('{{{' ++ t, buffer, acc, line, col) do
    acc = append_text(buffer, acc, line, col)

    case scan_unescaped_tag(t, [], line, col + 3) do
      {:error, %{rest: []}=opts} ->
        opts = Map.merge(opts, %{terminator: "}}}", starting: "{{{", starting_line: line, starting_col: col})
        {:error, TokenMissingError.exception(opts)}
      {:error, opts} ->
        {:error, TokenUnexpectedError.exception(opts)}
      {{:unescaped_variable, key, next_line, next_col}, t} ->
        scan(t, [], [{:unescaped_variable, key, line, col}|acc], next_line, next_col)
    end
  end

  defp scan('{{' ++ t, buffer, acc, line, col) do
    acc = append_text(buffer, acc, line, col)

    case scan_tag(t, [], line, col + 2) do
      {:error, %{rest: []}=opts} ->
        opts = Map.merge(opts, %{terminator: "}}", starting: "{{", starting_line: line, starting_col: col})
        {:error, TokenMissingError.exception(opts)}
      {:error, opts} ->
        {:error, TokenUnexpectedError.exception(opts)}
      {{tag, key, next_line, next_col}, t} ->
        scan(t, [], [{tag, key, line, col}|acc], next_line, next_col)
    end
  end

  defp scan('\r\n' ++ t, buffer, acc, line, col) do
    acc = append_text(buffer, acc, line, col)
    scan(t, [], [{:newline, "\r\n", line, col}|acc], line + 1, 0)
  end

  defp scan('\n' ++ t, buffer, acc, line, col) do
    acc = append_text(buffer, acc, line, col)
    scan(t, [], [{:newline, "\n", line, col}|acc], line + 1, 0)
  end

  defp scan([h|t], buffer, acc, line, col) do
    scan(t, [h|buffer], acc, line, col + 1)
  end

  defp scan([], buffer, acc, line, col) do
    acc = append_text(buffer, acc, line, col)
    Enum.reverse(acc)
  end

  defp scan_tag('}}' ++ t, acc, line, col) do
    if match?('}' ++ _, t) do
      Logger.warn(~s[template:#{line}:#{col}: tag end mismatched: "}}}"])
    end

    key = acc |> Enum.reverse |> List.flatten

    {type, key} = case key do
      '&' ++ key ->
        {:unescaped_variable, key}
      '#' ++ key ->
        {:section_begin, key}
      '/' ++ key ->
        {:section_end, key}
      '^' ++ key ->
        {:inverted_section_begin, key}
      '!' ++ key ->
        {:comment, key}
      '>' ++ key ->
        {:partial, key}
      key ->
        {:variable, key}
    end

    key = key |> to_string |> String.strip
    {{type, key, line, col + 2}, t}
  end

  defp scan_tag('{{{' ++ t, _acc, line, col) do
    {:error, %{parsed_line: line, parsed_col: col, token: "{{{", rest: t}}
  end

  defp scan_tag('{{' ++ t, _acc, line, col) do
    {:error, %{parsed_line: line, parsed_col: col, token: "{{", rest: t}}
  end

  defp scan_tag('\r\n' ++ t, acc, line, _col) do
    scan_tag(t, acc, line + 1, 0)
  end

  defp scan_tag('\n' ++ t, acc, line, _col) do
    scan_tag(t, acc, line + 1, 0)
  end

  defp scan_tag([h|t], acc, line, col) do
    scan_tag(t, [h|acc], line, col + 1)
  end

  defp scan_tag([], _acc, line, col) do
    {:error, %{parsed_line: line, parsed_col: col, rest: []}}
  end

  defp scan_unescaped_tag('}}}' ++ t, acc, line, col) do
    key = acc |> Enum.reverse |> to_string |> String.strip

    {{:unescaped_variable, key, line, col + 3}, t}
  end

  defp scan_unescaped_tag('}}' ++ t, _acc, line, col) do
    {:error, %{parsed_line: line, parsed_col: col, token: "}}", rest: t}}
  end

  defp scan_unescaped_tag('{{{' ++ t, _acc, line, col) do
    {:error, %{parsed_line: line, parsed_col: col, token: "{{{", rest: t}}
  end

  defp scan_unescaped_tag('{{' ++ t, _acc, line, col) do
    {:error, %{parsed_line: line, parsed_col: col, token: "{{", rest: t}}
  end

  defp scan_unescaped_tag('\r\n' ++ t, acc, line, _col) do
    scan_unescaped_tag(t, acc, line + 1, 0)
  end

  defp scan_unescaped_tag('\n' ++ t, acc, line, _col) do
    scan_unescaped_tag(t, acc, line + 1, 0)
  end

  defp scan_unescaped_tag([h|t], acc, line, col) do
    scan_unescaped_tag(t, [h|acc], line, col + 1)
  end

  defp scan_unescaped_tag([], _acc, line, col) do
    {:error, %{parsed_line: line, parsed_col: col, rest: []}}
  end

  defp append_text([], acc, _line, _col) do
    acc
  end

  defp append_text(buffer, acc, line, col) do
    value = buffer |> Enum.reverse |> to_string
    tag = text_type(value)
    [{tag, value, line, col - length(buffer)}|acc]
  end

  defp text_type(text) do
    case String.strip(text) do
      "" ->
        :whitespace
      _ ->
        :text
    end
  end
end
