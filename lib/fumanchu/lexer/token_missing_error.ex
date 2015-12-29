defmodule FuManchu.Lexer.TokenMissingError do
  defexception [:message]

  # TODO: Support passing in the filename of the template
  def exception(%{parsed_line: parsed_line, terminator: terminator, starting: starting, starting_line: starting_line}) do
    message = ~s[template:#{parsed_line}: missing terminator: #{inspect terminator} (for #{inspect starting} starting at line #{starting_line})]
    %__MODULE__{message: message}
  end
end
