defmodule FuManchu.Parser.TokenMissingError do
  defexception [:message]

  # TODO: Support passing in the filename of the template
  def exception(%{parsed_line: parsed_line, token_name: token_name, token: token, starting: starting, starting_line: starting_line}) do
    message = ~s[template:#{parsed_line}: missing #{token_name}: #{inspect token} (for #{inspect starting} starting at line #{starting_line})]
    %FuManchu.Parser.TokenMissingError{message: message}
  end
end

defmodule FuManchu.Parser.TokenUnrecognizedError do
  defexception [:message]

  # TODO: Support passing in the filename of the template
  def exception(%{line: line, token: token}) do
    message = ~s[template:#{line}: unrecognized token: #{inspect token}]
    %FuManchu.Parser.TokenUnrecognizedError{message: message}
  end
end

defmodule FuManchu.Parser do
  alias FuManchu.Parser.TokenMissingError
  alias FuManchu.Parser.TokenUnrecognizedError

  @collapsible_tags [:section_begin, :inverted_section_begin, :section_end, :comment, :partial]
  @passthrough_tokens [:variable, :unescaped_variable, :partial, :text, :newline, :whitespace]
  @marker_begin {:newline, "\n", 0}
  @marker_end   {:newline, "\n", -1}

  def parse(tokens) do
    case parse([@marker_begin] ++ tokens ++ [@marker_end], []) do
      {:error, error} ->
        {:error, error}
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
    case parse([h|t], []) do
      {{:section, ^name, _line, [^h|children]}, t} ->
        parse(t, [{:section, name, line, children}|acc])
      _ ->
        parsed_line = line_of_last_token(t, line)
        opts = %{parsed_line: parsed_line, token_name: "section end", token: "{{/#{name}}}", starting: "{{##{name}}}", starting_line: line}
        {:error, TokenMissingError.exception(opts)}
    end
  end

  defp parse([{:inverted_section_begin, name, line}|t], [h|_]=acc) do
    case parse([h|t], []) do
      {{:section, ^name, _line, [^h|children]}, t} ->
        parse(t, [{:inverted_section, name, line, children}|acc])
      _ ->
        parsed_line = line_of_last_token(t, line)
        opts = %{parsed_line: parsed_line, token_name: "section end", token: "{{/#{name}}}", starting: "{{^#{name}}}", starting_line: line}
        {:error, TokenMissingError.exception(opts)}
    end
  end

  defp parse([{:section_end, name, line}|t], acc) do
    {{:section, name, line, Enum.reverse(acc)}, t}
  end

  defp parse([{:comment, _, _}|t], acc) do
    parse(t, acc)
  end

  defp parse([{token, _, _}=h|t], acc)
      when token in @passthrough_tokens do
    parse(t, [h|acc])
  end

  defp parse([{token, _, line}|_t], _acc) do
    {:error, TokenUnrecognizedError.exception(%{token: token, line: line})}
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

  defp line_of_last_token(tokens, current_line) do
    case Enum.reverse(tokens) do
      [@marker_end, {_, _, line}|_] ->
        line
      [@marker_end] ->
        current_line
      [{_, _, line}|_] ->
        line
      [] ->
        current_line
    end
  end
end
