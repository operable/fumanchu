defmodule FuManchu.Generator do
  alias FuManchu.Generator.ASTNodeUnrecognizedError

  def generate(children) when is_list(children) do
    case generate_children(children) do
      {:error, error} ->
        {:error, error}
      children ->
        quoted_fun = quote do
          fn %{context: context, partials: partials} ->
            import FuManchu.Util

            fn context ->
              Enum.join(unquote(children))
            end.(stringify_keys(context))
          end
        end

        {:ok, quoted_fun}
    end
  end

  def generate({type, text, _line, _col})
      when type in [:text, :whitespace, :newline] do
    text
  end

  def generate({:variable, variable, _line, _col}) do
    quote do
      context
      |> access(unquote(variable))
      |> to_string
      |> encode_html_entities
    end
  end

  def generate({:unescaped_variable, variable, _line, _col}) do
    quote do
      context
      |> access(unquote(variable))
      |> to_string
    end
  end

  def generate({:section, name, _line, _col, children}) do
    case generate_children(children) do
      {:error, error} ->
        {:error, error}
      children ->
        quote do
          render = fn context ->
            unquote(children)
          end

          name = unquote(name)
          value = access(context, name, false)

          case value do
            false ->
              ""
            true ->
              render.(context)
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
  end

  def generate({:inverted_section, name, _line, _col, children}) do
    case generate_children(children) do
      {:error, error} ->
        {:error, error}
      children ->
        quote do
          render = fn context ->
            unquote(children)
          end

          name = unquote(name)
          value = access(context, name, false)

          case value do
            false ->
              render.(context)
            true ->
              ""
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

  def generate({:partial, name, line, col}) do
    generate({:partial, name, line, col, ""})
  end

  def generate({:partial, name, _line, _col, indent}) do
    quote do
      fn context ->
        source = partials
        |> Map.get(unquote(name), "")
        |> String.split("\n")
        |> Enum.map(&(unquote(indent) <> &1))
        |> Enum.join("\n")

        FuManchu.render!(source, context, partials)
      end.(context)
    end
  end

  def generate({name, _, line, col}) do
    {:error, ASTNodeUnrecognizedError.exception(%{node_name: name, line: line, col: col})}
  end

  defp generate_children(children) when is_list(children) do
    children = Enum.map(children, &generate/1)

    case Enum.find(children, &match?({:error, _}, &1)) do
      nil ->
        children
      error ->
        error
    end
  end
end
