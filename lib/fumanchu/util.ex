defmodule FuManchu.Util do
  def stringify_keys(map) when is_map(map) do
    for {k, v} <- map, into: %{},
      do: {stringify_key(k), stringify_value(v)}
  end
  def stringify_keys(list) when is_list(list),
    do: stringify_value(list)

  defp stringify_key(atom) when is_atom(atom),
    do: Atom.to_string(atom)
  defp stringify_key(bin) when is_binary(bin),
    do: bin

  defp stringify_value(map) when is_map(map),
    do: stringify_keys(map)
  defp stringify_value(list) when is_list(list),
    do: Enum.map(list, &stringify_value/1)
  defp stringify_value(scalar),
    do: scalar
end
