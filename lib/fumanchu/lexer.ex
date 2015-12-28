defmodule FuManchu.Lexer.TokenMissingError do
  defexception [:message]

  # TODO: Support passing in the filename of the template
  def exception(%{parsed_line: parsed_line, terminator: terminator, starting: starting, starting_line: starting_line}) do
    message = ~s[template:#{parsed_line}: missing terminator: #{inspect terminator} (for #{inspect starting} starting at line #{starting_line})]
    %FuManchu.Lexer.TokenMissingError{message: message}
  end
end

defmodule FuManchu.Lexer.TokenUnexpectedError do
  defexception [:message]

  # TODO: Support passing in the filename of the template
  def exception(%{parsed_line: parsed_line, token: token}) do
    message = ~s[template:#{parsed_line}: unexpected token: #{inspect token}]
    %FuManchu.Lexer.TokenUnexpectedError{message: message}
  end
end

defmodule FuManchu.Lexer do
  alias FuManchu.Lexer.TokenMissingError
  alias FuManchu.Lexer.TokenUnexpectedError

  def scan(bin) when is_binary(bin) do
    scan(String.to_char_list(bin))
  end

  def scan(char_list) do
    case scan(char_list, [], [], 1) do
      {:error, error} ->
        {:error, error}
      tokens ->
        {:ok, tokens}
    end
  end

  defp scan('{{{' ++ t, buffer, acc, line) do
    acc = append_text(buffer, acc, line)

    case scan_tag(t, [], line) do
      {:error, %{rest: []}=opts} ->
        opts = Map.merge(opts, %{terminator: "}}}", starting: "{{{", starting_line: line})
        {:error, TokenMissingError.exception(opts)}
      {:error, opts} ->
        {:error, TokenUnexpectedError.exception(opts)}
      {{:unescaped_variable, key, next_line}, t} ->
        scan(t, [], [{:unescaped_variable, key, line}|acc], next_line)
    end
  end

  defp scan('{{' ++ t, buffer, acc, line) do
    acc = append_text(buffer, acc, line)

    case scan_tag(t, [], line) do
      {:error, %{rest: []}=opts} ->
        opts = Map.merge(opts, %{terminator: "}}", starting: "{{", starting_line: line})
        {:error, TokenMissingError.exception(opts)}
      {:error, opts} ->
        {:error, TokenUnexpectedError.exception(opts)}
      {{tag, key, next_line}, t} ->
        scan(t, [], [{tag, key, line}|acc], next_line)
    end
  end

  defp scan('\r\n' ++ t, buffer, acc, line) do
    acc = append_text(buffer, acc, line)
    scan(t, [], [{:newline, "\r\n", line}|acc], line + 1)
  end

  defp scan('\n' ++ t, buffer, acc, line) do
    acc = append_text(buffer, acc, line)
    scan(t, [], [{:newline, "\n", line}|acc], line + 1)
  end

  defp scan([h|t], buffer, acc, line) do
    scan(t, [h|buffer], acc, line)
  end

  defp scan([], buffer, acc, line) do
    acc = append_text(buffer, acc, line)
    Enum.reverse(acc)
  end

  defp scan_tag('}}}' ++ t, acc, line) do
    key = acc |> Enum.reverse |> to_string |> String.strip

    {{:unescaped_variable, key, line}, t}
  end

  defp scan_tag('}}' ++ t, acc, line) do
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
    {{type, key, line}, t}
  end

  defp scan_tag('{{{' ++ t, _acc, line) do
    {:error, %{parsed_line: line, token: "{{{", rest: t}}
  end

  defp scan_tag('{{' ++ t, _acc, line) do
    {:error, %{parsed_line: line, token: "{{", rest: t}}
  end

  defp scan_tag('\r\n' ++ t, acc, line) do
    scan_tag(t, acc, line + 1)
  end

  defp scan_tag('\n' ++ t, acc, line) do
    scan_tag(t, acc, line + 1)
  end

  defp scan_tag([h|t], acc, line) do
    scan_tag(t, [h|acc], line)
  end

  defp scan_tag([], _acc, line) do
    {:error, %{parsed_line: line, rest: []}}
  end

  defp append_text([], acc, _line) do
    acc
  end

  defp append_text(buffer, acc, line) do
    value = buffer |> Enum.reverse |> to_string
    tag = text_type(value)
    [{tag, value, line}|acc]
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
