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

  def encode_html_entities(bin) when is_binary(bin),
    do: encode_html_entities(String.to_char_list(bin), [])
  def encode_html_entities(char_list) when is_list(char_list),
    do: encode_html_entities(char_list, [])
  def encode_html_entities(scalar),
    do: scalar

  # TODO: Support all html entities
  defp encode_html_entities([], acc),
    do: acc |> Enum.reverse |> to_string
  defp encode_html_entities('&' ++ t, acc),
    do: encode_html_entities(t, ['&amp;'|acc])
  defp encode_html_entities('"' ++ t, acc),
    do: encode_html_entities(t, ['&quot;'|acc])
  defp encode_html_entities('<' ++ t, acc),
    do: encode_html_entities(t, ['&lt;'|acc])
  defp encode_html_entities('>' ++ t, acc),
    do: encode_html_entities(t, ['&gt;'|acc])
  defp encode_html_entities([h|t], acc),
    do: encode_html_entities(t, [h|acc])

  def access(context, key),
    do: access(context, key, "")
  def access(context, ".", _default),
    do: context
  def access(context, key, default) when is_binary(key),
    do: access(context, String.split(key, "."), default)
  def access(context, [], default),
    do: context
  def access(context, [h|t], default) when is_map(context),
    do: access(Map.get(context, h, default), t, default)
  def access(_, _, default),
    do: default
end
