defmodule FuManchu.Generator.ASTNodeUnrecognizedError do
  defexception [:message]

  def exception(%{node_name: node_name, line: line}) do
    message = ~s[template:#{line}: unrecognized ast node: #{inspect node_name}]
    %__MODULE__{message: message}
  end
end
