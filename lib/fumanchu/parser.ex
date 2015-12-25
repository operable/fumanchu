defmodule FuManchu.Parser do
  @collapsible_tags [:section_begin, :inverted_section_begin, :section_end, :comment, :partial]
  @marker_begin {:newline, "\n", 0}
  @marker_end   {:newline, "\n", -1}

  def parse(tokens) do
    case parse([@marker_begin] ++ tokens ++ [@marker_end], []) do
      :error ->
        :error
      ast ->
        {:ok, ast}
    end
  end

  defp parse([{:newline, _, _}=newline, {:whitespace, whitespace, _}, {:partial, name, line}, {:newline, _, _}|t], acc) do
    parse(t, [{:partial, name, line, whitespace}, newline|acc])
  end

  defp parse([{:newline, _, _}=newline, {:whitespace, _, _}, {:newline, _, _}|t], acc) do
    parse(t, [newline|acc])
  end

  defp parse([{:newline, _, _}=newline, {type, _, _}=tag, {:newline, _, _}|t], acc)
      when type in @collapsible_tags do
    parse([tag|t], [newline|acc])
  end

  defp parse([{:newline, _, _}=newline, {:whitespace, _, _}, {type, _, _}=tag, {:newline, _, _}|t], acc)
      when type in @collapsible_tags do
    parse([tag|t], [newline|acc])
  end

  defp parse([{:section_begin, name, line}|t], [h|_]=acc) do
    {{:section, ^name, _line, [^h|children]}, t} = parse([h|t], [])
    parse(t, [{:section, name, line, children}|acc])
  end

  defp parse([{:inverted_section_begin, name, line}|t], [h|_]=acc) do
    {{:section, ^name, _line, [^h|children]}, t} = parse([h|t], [])
    parse(t, [{:inverted_section, name, line, children}|acc])
  end

  defp parse([{:section_end, name, line}|t], acc) do
    {{:section, name, line, Enum.reverse(acc)}, t}
  end

  defp parse([{:comment, _, _}|t], acc) do
    parse(t, acc)
  end

  defp parse([h|t], acc) do
    parse(t, [h|acc])
  end

  defp parse([], [@marker_end|acc]) do
    parse([], acc)
  end

  defp parse([], acc) do
    [@marker_begin|acc] = Enum.reverse(acc)
    acc
  end
end
