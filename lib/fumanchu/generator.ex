defmodule FuManchu.Generator do
  def generate(children) when is_list(children) do
    elements = Enum.map(children, &generate/1)

    quote do
      fn bindings ->
        import FuManchu.Util
        bindings = stringify_keys(bindings)
        Enum.join(unquote(elements))
      end
    end
  end

  def generate({:text, text}) do
    text
  end

  def generate({:variable, '.'}) do
    quote do
      bindings
    end
  end

  def generate({:variable, variable}) do
    quote do
      Map.get(bindings, unquote(to_key(variable)), "")
    end
  end

  def generate({:section, name, children}) do
    elements = Enum.map(children, &generate/1)

    quote do
      name = unquote(to_key(name))
      value = Map.get(bindings, name, false)

      bindings = case value do
        map when is_map(map) ->
          Map.put(bindings, name, map)
        list when is_list(list) ->
          list
        _ ->
          bindings
      end

      case value do
        list when is_list(list) ->
          Enum.map(bindings, fn bindings ->
            unquote(elements)
          end)
        true ->
          unquote(elements)
        false ->
          ""
      end
    end
  end

  def to_key(char_list) do
    char_list
    |> to_string
  end
end
