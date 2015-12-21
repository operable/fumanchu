defmodule FuManchu.Parser do
  def parse(tokens) do
    case parse(tokens, []) do
      {:error, _} = error ->
        error
      ast ->
        {:ok, ast}
    end
  end

  defp parse([{:tag_open, _raw, line}|t], acc) do
    {{type, key, _line}, t} = parse_tag(t, [])
    parse([{type, key, line}|t], acc)
  end

  defp parse([{:unescaped_tag_open, _raw, line}|t], acc) do
    {{:unescaped_variable, key, _line}, t} = parse_tag(:unescaped_variable, t, [])
    parse([{:unescaped_variable, key, line}|t], acc)
  end

  defp parse([{:section_begin, name, line}|t], acc) do
    {{:section, ^name, _line, children}, t} = parse(t, [])
    parse(t, [{:section, name, line, children}|acc])
  end

  defp parse([{:inverted_section_begin, name, _line}|t], acc) do
    {{:section, ^name, line, children}, t} = parse(t, [])
    parse(t, [{:inverted_section, name, line, children}|acc])
  end

  defp parse([{:section_end, name, line}|t], acc) do
    {{:section, name, line, Enum.reverse(acc)}, t}
  end

  defp parse([{:comment, _, line}|t], acc) do
    next_line = case t do
      [{_, _, next_line}|_] ->
        next_line
      _ ->
        line
    end

    {stripped_acc, prev} = pop_line(acc, line)
    {stripped_t, next}   = pop_line(t, next_line)

    whitespace_line = Enum.all?(prev ++ next, fn {:text, text, _} ->
      String.strip(text) == ""
    end)

    case whitespace_line do
      true ->
        parse(stripped_t, stripped_acc)
      false ->
        parse(t, acc)
    end
  end

  defp parse([h|t], acc) do
    parse(t, [h|acc])
  end

  defp parse([], acc) do
    Enum.reverse(acc)
  end

  defp parse_tag([{:tag_type, "&", _}|t], []) do
    parse_tag(:unescaped_variable, t, [])
  end

  defp parse_tag([{:tag_type, "#", _}|t], []) do
    parse_tag(:section_begin, t, [])
  end

  defp parse_tag([{:tag_type, "/", _}|t], []) do
    parse_tag(:section_end, t, [])
  end

  defp parse_tag([{:tag_type, "^", _}|t], []) do
    parse_tag(:inverted_section_begin, t, [])
  end

  defp parse_tag([{:tag_type, "!", _}|t], []) do
    parse_tag(:comment, t, [])
  end

  defp parse_tag([{:tag_type, ">", _}|t], []) do
    parse_tag(:partial, t, [])
  end

  defp parse_tag(t, []) do
    parse_tag(:variable, t, [])
  end

  defp parse_tag(type, [{:tag_close, _, line}|t], acc) do
    key = acc
    |> Enum.reverse
    |> Enum.join
    |> String.strip

    {{type, key, line}, t}
  end

  defp parse_tag(:unescaped_variable, [{:unescaped_tag_close, _, line}|t], acc) do
    key = acc
    |> Enum.reverse
    |> Enum.join
    |> String.strip

    {{:unescaped_variable, key, line}, t}
  end

  defp parse_tag(type, [{:tag_key, key, _}|t], acc) do
    parse_tag(type, t, [key|acc])
  end

  defp pop_line(buffer, line) do
    pop_line(buffer, line, [])
  end

  defp pop_line([{_, _, line}=h|t], line, acc) do
    pop_line(t, line, [h|acc])
  end

  defp pop_line(buffer, _, acc) do
    {buffer, Enum.reverse(acc)}
  end
end
