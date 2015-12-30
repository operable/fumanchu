defmodule FuManchu.Lexer.TokenUnexpectedError do
  defexception [:message]

  # TODO: Support passing in the filename of the template
  def exception(%{parsed_line: parsed_line, token: token}) do
    message = ~s[template:#{parsed_line}: unexpected token: #{inspect token}]
    %__MODULE__{message: message}
  end
end
