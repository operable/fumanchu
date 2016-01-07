defmodule FuManchu.Parser do
  alias FuManchu.Lexer
  alias FuManchu.Parser.TokenMissingError
  alias FuManchu.Parser.TokenUnrecognizedError

  @collapsible_tags [:section_begin, :inverted_section_begin, :section_end, :comment, :partial]
  @passthrough_tokens [:variable, :unescaped_variable, :partial, :text, :newline, :whitespace]
  @extended_tokens [:section, :inverted_section, :partial]
  @marker_begin {:newline, "\n", 0, 0}
  @marker_end   {:newline, "\n", -1, 0}

  @type line :: pos_integer
  @type column :: non_neg_integer
  @type simple_node  :: {Atom, String.t, line, column}
  @type partial_node :: {Atom, String.t, line, column, String.t}
  @type section_node :: {Atom, String.t, line, column, [ast_node, ...]}
  @type ast_node :: simple_node | partial_node | section_node
  @type ast :: [ast_node, ...]

  @doc """
  Parses a list of tokens producing an AST. The lexer handles creating tokens
  for things like variables, section beginnings and section ends. So, most of
  the work here is to collapse whitespace, group sections, and remove comments.

  When parsing we temporarily append whitespace markers to the beginning and
  end of the token list to simplify whitespace rules around template
  boundaries.
  """

  @spec parse(Lexer.tokens) :: {:ok, ast} | {:error, any}
  def parse(tokens) do
    case parse([@marker_begin] ++ tokens ++ [@marker_end], []) do
      {:error, error} ->
        {:error, error}
      ast ->
        {:ok, ast}
    end
  end

  defp parse([{:newline, _, _, _}=newline, {:whitespace, whitespace, _, _}, {:partial, name, line, col}, {:newline, _, _, _}|t], acc) do
    parse(t, [{:partial, name, line, col, whitespace}, newline|acc])
  end

  defp parse([{:newline, _, _, _}=newline, {:whitespace, _, _, _}, {:newline, _, _, _}|t], acc) do
    parse(t, [newline|acc])
  end

  defp parse([{:newline, _, _, _}=newline, {type1, _, _, _}=tag1, {:newline, _, _, _}, {type2, _, _, _}=tag2, {:newline, _, _, _}|t], acc)
      when type1 in @collapsible_tags and type2 in @collapsible_tags do
    parse([tag1, tag2|t], [newline|acc])
  end

  defp parse([{:newline, _, _, _}=newline, {type, _, _, _}=tag, {:newline, _, _, _}|t], acc)
      when type in @collapsible_tags do
    parse([tag|t], [newline|acc])
  end

  defp parse([{:newline, _, _, _}=newline, {:whitespace, _, _, _}, {type, _, _, _}=tag, {:newline, _, _, _}|t], acc)
      when type in @collapsible_tags do
    parse([tag|t], [newline|acc])
  end

  defp parse([{:section_begin, name, line, col}=h|t], [prev|_]=acc) do
    case parse([prev|t], []) do
      {{:section, ^name, _line, _col, [^prev|children]}, t} ->
        parse(t, [{:section, name, line, col, children}|acc])
      _ ->
        {_, _, parsed_line, parsed_col} = last_token([h|t])
        opts = %{parsed_line: parsed_line, parsed_col: parsed_col, token_name: "section end", token: "{{/#{name}}}", starting: "{{##{name}}}", starting_line: line, starting_col: col}
        {:error, TokenMissingError.exception(opts)}
    end
  end

  defp parse([{:inverted_section_begin, name, line, col}=h|t], [prev|_]=acc) do
    case parse([prev|t], []) do
      {{:section, ^name, _line, _col, [^prev|children]}, t} ->
        parse(t, [{:inverted_section, name, line, col, children}|acc])
      _ ->
        {_, _, parsed_line, parsed_col} = last_token([h|t])
        opts = %{parsed_line: parsed_line, parsed_col: parsed_col, token_name: "section end", token: "{{/#{name}}}", starting: "{{^#{name}}}", starting_line: line, starting_col: col}
        {:error, TokenMissingError.exception(opts)}
    end
  end

  defp parse([{:section_end, name, line, col}|t], acc) do
    {{:section, name, line, col, Enum.reverse(acc)}, t}
  end

  defp parse([{:comment, _, _, _}|t], acc) do
    parse(t, acc)
  end

  defp parse([{token, _, _, _}=h|t], acc)
      when token in @passthrough_tokens do
    parse(t, [h|acc])
  end

  defp parse([{token, _, _, _, _}=h|t], acc)
      when token in @extended_tokens do
    parse(t, [h|acc])
  end

  defp parse([{token, _, line, col}|_t], _acc) do
    {:error, TokenUnrecognizedError.exception(%{token: token, line: line, col: col})}
  end

  defp parse([], [@marker_end|acc]) do
    parse([], acc)
  end

  defp parse([], acc) do
    case Enum.reverse(acc) do
      [@marker_begin|acc] ->
        acc
      acc ->
        acc
    end
  end

  defp last_token(tokens) do
    case Enum.reverse(tokens) do
      [@marker_end, token|_] ->
        token
      [token|_] ->
        token
    end
  end
end
