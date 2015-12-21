defmodule FuManchu.Parser do
  def parse(tokens) do
    case parse(tokens, []) do
      {:error, _} = error ->
        error
      ast ->
        {:ok, ast}
    end
  end

  defp parse([{:tag_open, _, _}|t], acc) do
    {tag, t} = parse_tag(t, [])
    parse([tag|t], acc)
  end

  defp parse([{:unescaped_tag_open, _, _}|t], acc) do
    {tag, t} = parse_tag(:unescaped_variable, t, [])
    parse([tag|t], acc)
  end

  defp parse([{:section_begin, name}|t], acc) do
    {{:section, ^name, _}=section, t} = parse(t, [])
    parse(t, [section|acc])
  end

  defp parse([{:inverted_section_begin, name}|t], acc) do
    {{:section, ^name, children}=section, t} = parse(t, [])
    parse(t, [{:inverted_section, name, children}|acc])
  end

  defp parse([{:section_end, name}|t], acc) do
    {{:section, name, Enum.reverse(acc)}, t}
  end

  defp parse([{:comment, _}|t], acc) do
    parse(t, acc)
  end

  defp parse([{token, value}|t], acc) do
    parse(t, [{token, value}|acc])
  end

  defp parse([{token, value, _line}|t], acc) do
    parse(t, [{token, value}|acc])
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

  defp parse_tag(type, [{:tag_close, _, _}|t], acc) do
    key = acc
    |> Enum.reverse
    |> Enum.join
    |> String.strip

    {{type, key}, t}
  end

  defp parse_tag(:unescaped_variable, [{:unescaped_tag_close, _, _}|t], acc) do
    key = acc
    |> Enum.reverse
    |> Enum.join
    |> String.strip

    {{:unescaped_variable, key}, t}
  end


  defp parse_tag(type, [{:tag_key, key, _}|t], acc) do
    parse_tag(type, t, [key|acc])
  end
end
