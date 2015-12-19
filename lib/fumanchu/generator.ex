defmodule FuManchu.Generator do
  def generate(children) when is_list(children) do
    elements = Enum.map(children, &generate/1)

    quote do
      fn assigns ->
        Enum.join(unquote(elements))
      end
    end
  end

  def generate({:text, text}) do
    text
  end

  def generate({:variable, '.'}) do
    quote do
      assigns
    end
  end

  def generate({:variable, variable}) do
    quote do
      Map.get(assigns, unquote(to_key(variable)), "")
    end
  end

  def generate({:section, name, children}) do
    elements = Enum.map(children, &generate/1)

    quote do
      name = unquote(to_key(name))
      value = Map.get(assigns, name, false)

      assigns = case value do
        map when is_map(map) ->
          Map.put(assigns, name, map)
        list when is_list(list) ->
          list
        _ ->
          assigns
      end

      case value do
        list when is_list(list) ->
          Enum.map(assigns, fn assigns ->
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
