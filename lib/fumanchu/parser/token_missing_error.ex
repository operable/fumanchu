defmodule FuManchu.Parser.TokenMissingError do
  defexception [:message]

  # TODO: Support passing in the filename of the template
  def exception(%{parsed_line: parsed_line, parsed_col: parsed_col, token_name: token_name, token: token, starting: starting, starting_line: starting_line, starting_col: starting_col}) do
    message = ~s[template:#{parsed_line}:#{parsed_col}: missing #{token_name}: #{inspect token} (for #{inspect starting} starting at line #{starting_line}, column #{starting_col})]
    %__MODULE__{message: message}
  end
end
