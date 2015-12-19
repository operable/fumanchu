defmodule FuManchu.Parser do
  def parse(tokens) do
    case parse(tokens, []) do
      {:error, _} = error ->
        error
      ast ->
        {:ok, ast}
    end
  end

  def parse([{:inverted_section_begin, name}|t], acc) do
    {section, rest} = parse(t, [])

    case section do
      {:section, ^name, children} ->
        inverted_section = {:inverted_section, name, children}
        parse(rest, [inverted_section|acc])
      _ ->
        {:error, "Missing end to section: #{name}"}
    end
  end

  def parse([{:section_begin, name}|t], acc) do
    {section, rest} = parse(t, [])

    case section do
      {:section, ^name, _} ->
        parse(rest, [section|acc])
      _ ->
        {:error, "Missing end to section: #{name}"}
    end
  end

  def parse([{:section_end, name}|t], acc) do
    {{:section, name, Enum.reverse(acc)}, t}
  end

  def parse([{:comment, _}|t], acc) do
    parse(t, acc)
  end

  def parse([h|t], acc) do
    parse(t, [h|acc])
  end

  def parse([], acc) do
    Enum.reverse(acc)
  end
end
