defmodule FuManchu.Parser.TokenUnrecognizedError do
  defexception [:message]

  # TODO: Support passing in the filename of the template
  def exception(%{line: line, col: col, token: token}) do
    message = ~s[template:#{line}:#{col}: unrecognized token: #{inspect token}]
    %__MODULE__{message: message}
  end
end
