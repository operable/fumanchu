defmodule FuManchu.Generator do
  def generate(children) when is_list(children) do
    elements = Enum.map(children, &generate/1)

    quote do
      fn context ->
        import FuManchu.Util

        fn context ->
          Enum.join(unquote(elements))
        end.(stringify_keys(context))
      end
    end
  end

  def generate({:text, text, _line}) do
    text
  end

  def generate({:variable, variable, _line}) do
    quote do
      context
      |> access(unquote(variable))
      |> encode_html_entities
    end
  end

  def generate({:unescaped_variable, variable, _line}) do
    quote do
      access(context, unquote(variable))
    end
  end

  def generate({:section, name, _line, children}) do
    elements = Enum.map(children, &generate/1)

    quote do
      render = fn context ->
        unquote(elements)
      end

      name = unquote(name)
      value = access(context, name, false)

      case value do
        false ->
          ""
        true ->
          render.(context)
        %{} ->
          ""
        map when is_map(map) ->
          render.(Map.merge(context, map))
        [] ->
          ""
        list when is_list(list) ->
          Enum.map(list, fn item ->
            render.(item)
          end)
      end
    end
  end

  def generate({:inverted_section, name, _line, children}) do
    elements = Enum.map(children, &generate/1)

    quote do
      render = fn context ->
        unquote(elements)
      end

      name = unquote(name)
      value = access(context, name, false)

      case value do
        false ->
          render.(context)
        true ->
          ""
        %{} ->
          render.(context)
        map when is_map(map) ->
          ""
        [] ->
          render.(context)
        list when is_list(list) ->
          ""
      end
    end
  end
end
