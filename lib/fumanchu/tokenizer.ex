defmodule FuManchu.Tokenizer do
  def tokenize(bin) when is_binary(bin) do
    tokenize(String.to_char_list(bin))
  end

  def tokenize(char_list) do
    tokenize(char_list, [], [], 1)
  end

  defp tokenize('{{{' ++ t, buffer, acc, line) do
    acc = append_buffer(:text, buffer, acc, line)
    token = {:unescaped_tag_open, "{{{", line}
    tokenize_unescaped_tag_key(t, [], [token|acc], line)
  end

  defp tokenize('{{' ++ t, buffer, acc, line) do
    acc = append_buffer(:text, buffer, acc, line)
    token = {:tag_open, "{{", line}
    tokenize_tag_type(t, [token|acc], line)
  end

  defp tokenize('\n' ++ t, buffer, acc, line) do
    acc = append_buffer(:text, '\n' ++ buffer, acc, line)
    tokenize(t, [], acc, line + 1)
  end

  defp tokenize([h|t], buffer, acc, line) do
    tokenize(t, [h|buffer], acc, line)
  end

  defp tokenize([], [], acc, _line) do
    Enum.reverse(acc)
  end

  defp tokenize([], buffer, acc, line) do
    acc = append_buffer(:text, buffer, acc, line)
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

  defp tokenize_tag_key('\n' ++ t, buffer, acc, line) do
    acc = append_buffer(:tag_key, '\n' ++ buffer, acc, line)
    tokenize_tag_key(t, [], acc, line + 1)
  end

  defp tokenize_tag_key('}}' ++ t, buffer, acc, line) do
    acc = append_buffer(:tag_key, buffer, acc, line)
    token = {:tag_close, "}}", line}
    tokenize(t, [], [token|acc], line)
  end

  defp tokenize_tag_key([h|t], buffer, acc, line) do
    tokenize_tag_key(t, [h|buffer], acc, line)
  end

  defp tokenize_unescaped_tag_key('\n' ++ t, buffer, acc, line) do
    acc = append_buffer(:tag_key, '\n' ++ buffer, acc, line)
    tokenize_unescaped_tag_key(t, [], acc, line + 1)
  end

  defp tokenize_unescaped_tag_key('}}}' ++ t, buffer, acc, line) do
    acc = append_buffer(:tag_key, buffer, acc, line)
    token = {:unescaped_tag_close, "}}}", line}
    tokenize(t, [], [token|acc], line)
  end

  defp tokenize_unescaped_tag_key([h|t], buffer, acc, line) do
    tokenize_unescaped_tag_key(t, [h|buffer], acc, line)
  end

  defp append_buffer(_type, [], acc, _line) do
    acc
  end

  defp append_buffer(type, buffer, acc, line) do
    value = buffer |> Enum.reverse |> to_string
    token = {type, value, line}
    [token|acc]
  end
end
