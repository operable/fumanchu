defmodule FuManchu.Generator.ASTNodeUnrecognizedError do
  defexception [:message]

  def exception(%{node_name: node_name, line: line, col: col}) do
    message = ~s[template:#{line}:#{col}: unrecognized ast node: #{inspect node_name}]
    %__MODULE__{message: message}
  end
end
