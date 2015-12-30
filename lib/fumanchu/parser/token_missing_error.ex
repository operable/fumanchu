defmodule FuManchu.Parser.TokenMissingError do
  defexception [:message]

  # TODO: Support passing in the filename of the template
  def exception(%{parsed_line: parsed_line, token_name: token_name, token: token, starting: starting, starting_line: starting_line}) do
    message = ~s[template:#{parsed_line}: missing #{token_name}: #{inspect token} (for #{inspect starting} starting at line #{starting_line})]
    %__MODULE__{message: message}
  end
end
