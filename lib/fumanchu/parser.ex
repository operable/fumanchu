defmodule FuManchu.Parser do
  @collapsible_tags [:section_begin, :inverted_section_begin, :section_end, :comment]
  @marker {:newline, "\n", 0}

  def parse(tokens) do
    case parse([@marker] ++ tokens ++ [@marker], []) do
      :error ->
        :error
      ast ->
        {:ok, ast}
    end
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

  defp parse([], [@marker|acc]) do
    parse([], acc)
  end

  defp parse([], acc) do
    [@marker|acc] = Enum.reverse(acc)
    acc
  end
end
