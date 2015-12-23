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

  defp parse([{:section_begin, name, line}, {:newline, _, _}=newline|t], []) do
    {{:section, ^name, _line, [{:newline, _, _}|children]}, t} = parse([newline|t], [])
    parse(t, [{:section, name, line, children}])
  end

  defp parse([{:section_begin, name, line}, {:newline, _, _}=newline|t], [{:whitespace, _, _}]) do
    {{:section, ^name, _line, [{:newline, _, _}|children]}, t} = parse([newline|t], [])
    parse(t, [{:section, name, line, children}])
  end

  defp parse([{:section_begin, name, line}, {:newline, _, _}=newline|t], [{:newline, _, _}|_]=acc) do
    {{:section, ^name, _line, [{:newline, _, _}|children]}, t} = parse([newline|t], [])
    parse(t, [{:section, name, line, children}|acc])
  end

  defp parse([{:section_begin, name, line}|t], acc) do
    {{:section, ^name, _line, children}, t} = parse(t, [])
    parse(t, [{:section, name, line, children}|acc])
  end

  defp parse([{:inverted_section_begin, name, line}, {:newline, _, _}=newline|t], []) do
    {{:section, ^name, _line, [{:newline, _, _}|children]}, t} = parse([newline|t], [])
    parse(t, [{:inverted_section, name, line, children}])
  end

  defp parse([{:inverted_section_begin, name, line}, {:newline, _, _}=newline|t], [{:whitespace, _, _}]) do
    {{:section, ^name, _line, [{:newline, _, _}|children]}, t} = parse([newline|t], [])
    parse(t, [{:inverted_section, name, line, children}])
  end

  defp parse([{:inverted_section_begin, name, line}, {:newline, _, _}=newline|t], [{:newline, _, _}|_]=acc) do
    {{:section, ^name, _line, [{:newline, _, _}|children]}, t} = parse([newline|t], [])
    parse(t, [{:inverted_section, name, line, children}|acc])
  end

  defp parse([{:inverted_section_begin, name, _line}|t], acc) do
    {{:section, ^name, line, children}, t} = parse(t, [])
    parse(t, [{:inverted_section, name, line, children}|acc])
  end

  defp parse([{:section_end, name, line}, {:newline, _, _}|t], [{:newline, _, _}|_]=acc) do
    {{:section, name, line, Enum.reverse(acc)}, t}
  end

  defp parse([{:section_end, name, line}|t], acc) do
    {{:section, name, line, Enum.reverse(acc)}, t}
  end

  defp parse([{:comment, _, _}, {:newline, _, _}|t], [{:whitespace, _, _}, {:newline, _, _}=newline|acc]) do
    parse(t, [newline|acc])
  end

  defp parse([{:partial, _, _}=partial, {:newline, _, _}|t], [{:newline, _, _}|_]=acc) do
    parse([partial|t], acc)
  end

  defp parse([{:comment, _, _}, {:newline, _, _}|t], [{:newline, _, _}|_]=acc) do
    parse(t, acc)
  end

  defp parse([{:comment, _, _}], [{:whitespace, _, _}, {:newline, _, _}=newline|acc]) do
    parse([], [newline|acc])
  end

  defp parse([{:comment, _, _}|t], acc) do
    parse(t, acc)
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

  defp parse_tag(type, [{tag_close, _, line}|t], acc)
      when tag_close in [:tag_close, :unescaped_tag_close] do
    key = acc
    |> Enum.reverse
    |> Enum.join
    |> String.strip

    key = case key do
      "." ->
        key
      key ->
        String.split(key, ".")
    end

    {{type, key, line}, t}
  end

  defp parse_tag(type, [{:tag_key, key, _}|t], acc) do
    parse_tag(type, t, [key|acc])
  end
end
