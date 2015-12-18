defmodule FuManchu.Lexer do
  def tokenize(bin) when is_binary(bin) do
    tokenize(String.to_char_list(bin))
  end

  def tokenize(list) do
    tokenize(list, [], [])
  end

  defp tokenize('{{{' ++ t, buffer, acc) do
    tokenize_unescaped_tag(:unescaped_variable, t, buffer, acc)
  end

  defp tokenize('{{& ' ++ t, buffer, acc) do
    tokenize_tag(:unescaped_variable, t, buffer, acc)
  end

  defp tokenize('{{#' ++ t, buffer, acc) do
    tokenize_tag(:section_begin, t, buffer, acc)
  end

  defp tokenize('{{^' ++ t, buffer, acc) do
    tokenize_tag(:inverted_section_begin, t, buffer, acc)
  end

  defp tokenize('{{/' ++ t, buffer, acc) do
    tokenize_tag(:section_end, t, buffer, acc)
  end

  defp tokenize('{{! ' ++ t, buffer, acc) do
    tokenize_tag(:comment, t, buffer, acc)
  end

  defp tokenize('{{> ' ++ t, buffer, acc) do
    tokenize_tag(:partial, t, buffer, acc)
  end

  defp tokenize('{{' ++ t, buffer, acc) do
    tokenize_tag(:variable, t, buffer, acc)
  end

  defp tokenize([h|t], buffer, acc) do
    tokenize(t, [h|buffer], acc)
  end

  defp tokenize([], buffer, acc) do
    acc = tokenize_text(buffer, acc)
    {:ok, Enum.reverse(acc)}
  end

  def tokenize_unescaped_tag(type, t, buffer, acc) do
    case unescaped_tag(t, []) do
      {:ok, tag, rest} ->
        acc = tokenize_text(buffer, acc)
        token = {type, Enum.reverse(tag)}
        tokenize(rest, [], [token|acc])
      {:error, _, _} = error ->
        error
    end
  end

  def tokenize_tag(type, t, buffer, acc) do
    case tag(t, []) do
      {:ok, tag, rest} ->
        acc = tokenize_text(buffer, acc)
        token = {type, Enum.reverse(tag)}
        tokenize(rest, [], [token|acc])
      {:error, _, _} = error ->
        error
    end
  end

  def tokenize_text([], acc) do
    acc
  end

  def tokenize_text(buffer, acc) do
    token = {:text, Enum.reverse(buffer)}
    [token|acc]
  end

  def unescaped_tag('}}}' ++ t, buffer) do
    {:ok, buffer, t}
  end

  def unescaped_tag([h|t], buffer) do
    unescaped_tag(t, [h|buffer])
  end

  def unescaped_tag([], _) do
    {:error, "Missing token '}}}'"}
  end

  def tag('}}' ++ t, buffer) do
    {:ok, buffer, t}
  end

  def tag([h|t], buffer) do
    tag(t, [h|buffer])
  end

  def tag([], _) do
    {:error, "Missing token '}}'"}
  end
end
