defmodule FuManchu.Tokenizer do
  def tokenize(bin) when is_binary(bin) do
    tokenize(String.to_char_list(bin))
  end

  def tokenize(char_list) do
    case tokenize(char_list, [], [], 1) do
      :error ->
        :error
      tokens ->
        {:ok, tokens}
    end
  end

  defp tokenize('{{{' ++ t, buffer, acc, line) do
    acc = append_text(buffer, acc, line)
    token = {:unescaped_tag_open, "{{{", line}
    tokenize_unescaped_tag_key(t, [], [token|acc], line)
  end

  defp tokenize('{{' ++ t, buffer, acc, line) do
    acc = append_text(buffer, acc, line)
    token = {:tag_open, "{{", line}
    tokenize_tag_type(t, [token|acc], line)
  end

  defp tokenize('\r\n' ++ t, buffer, acc, line) do
    acc = append_text(buffer, acc, line)
    acc = append_newline('\r\n', acc, line)
    tokenize(t, [], acc, line + 1)
  end

  defp tokenize('\n' ++ t, buffer, acc, line) do
    acc = append_text(buffer, acc, line)
    acc = append_newline('\n', acc, line)
    tokenize(t, [], acc, line + 1)
  end

  defp tokenize([h|t], buffer, acc, line) do
    tokenize(t, [h|buffer], acc, line)
  end

  defp tokenize([], [], acc, _line) do
    Enum.reverse(acc)
  end

  defp tokenize([], buffer, acc, line) do
    acc = append_text(buffer, acc, line)
    tokenize([], [], acc, line)
  end

  defp tokenize_tag_type('&' ++ t, acc, line) do
    token = {:tag_type, "&", line}
    tokenize_tag_key(t, [], [token|acc], line)
  end

  defp tokenize_tag_type('#' ++ t, acc, line) do
    token = {:tag_type, "#", line}
    tokenize_tag_key(t, [], [token|acc], line)
  end

  defp tokenize_tag_type('/' ++ t, acc, line) do
    token = {:tag_type, "/", line}
    tokenize_tag_key(t, [], [token|acc], line)
  end

  defp tokenize_tag_type('^' ++ t, acc, line) do
    token = {:tag_type, "^", line}
    tokenize_tag_key(t, [], [token|acc], line)
  end

  defp tokenize_tag_type('!' ++ t, acc, line) do
    token = {:tag_type, "!", line}
    tokenize_tag_key(t, [], [token|acc], line)
  end

  defp tokenize_tag_type('>' ++ t, acc, line) do
    token = {:tag_type, ">", line}
    tokenize_tag_key(t, [], [token|acc], line)
  end

  defp tokenize_tag_type(t, acc, line) do
    tokenize_tag_key(t, [], acc, line)
  end

  defp tokenize_tag_key('\r\n' ++ t, buffer, acc, line) do
    acc = append_tag_key(buffer, acc, line)
    acc = append_newline('\r\n', acc, line)
    tokenize_tag_key(t, [], acc, line + 1)
  end

  defp tokenize_tag_key('\n' ++ t, buffer, acc, line) do
    acc = append_tag_key(buffer, acc, line)
    acc = append_newline('\n', acc, line)
    tokenize_tag_key(t, [], acc, line + 1)
  end

  defp tokenize_tag_key('}}' ++ t, buffer, acc, line) do
    acc = append_tag_key(buffer, acc, line)
    token = {:tag_close, "}}", line}
    tokenize(t, [], [token|acc], line)
  end

  defp tokenize_tag_key([h|t], buffer, acc, line) do
    tokenize_tag_key(t, [h|buffer], acc, line)
  end

  defp tokenize_unescaped_tag_key('\n' ++ t, buffer, acc, line) do
    acc = append_tag_key('\n' ++ buffer, acc, line)
    tokenize_unescaped_tag_key(t, [], acc, line + 1)
  end

  defp tokenize_unescaped_tag_key('}}}' ++ t, buffer, acc, line) do
    acc = append_tag_key(buffer, acc, line)
    token = {:unescaped_tag_close, "}}}", line}
    tokenize(t, [], [token|acc], line)
  end

  defp tokenize_unescaped_tag_key([h|t], buffer, acc, line) do
    tokenize_unescaped_tag_key(t, [h|buffer], acc, line)
  end

  def append_text([], acc, _line) do
    acc
  end

  def append_text(buffer, acc, line) do
    value = buffer |> Enum.reverse |> to_string

    tag = case String.strip(value) do
      "" ->
        :whitespace
      _ ->
        :text
    end

    token = {tag, value, line}
    [token|acc]
  end

  def append_newline([], acc, _line) do
    acc
  end

  def append_newline(buffer, acc, line) do
    value = buffer |> to_string
    token = {:newline, value, line}
    [token|acc]
  end

  def append_tag_key([], acc, _line) do
    acc
  end

  def append_tag_key(buffer, acc, line) do
    value = buffer |> Enum.reverse |> to_string
    token = {:tag_key, value, line}
    [token|acc]
  end
end
