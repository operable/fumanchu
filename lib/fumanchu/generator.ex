defmodule FuManchu.Generator do
  alias FuManchu.Generator.ASTNodeUnrecognizedError
  alias FuManchu.Parser

  @type quoted :: any

  @doc """
  Generates a quoted anonymous function from the given ast, typically created
  by the parser and handled off to the compiler and evaled when rendering a
  template. Any Errors encountured while generating are returned as `{:error, error}`.

  The `generate/1` function is called recursively as we "walk" the AST. Each node
  is converted into it's representation of Elixir code, resulting in a final
  anonymous function that takes context and partials as arguments and returns
  the rendered template. In most cases we generate an IIFE, immediately-invoked
  function expression, for each node with changes to the current context.
  Before returning, expressions from sibling nodes are concatenated together
  forming the final rendering of the template.
  """

  @spec generate(Parser.ast | Parser.ast_node) :: {:ok, quoted} | {:error, any}
  def generate(children) when is_list(children) do
    case generate_children(children) do
      {:error, error} ->
        {:error, error}
      children ->
        quoted_fun = quote do
          fn %{context: context, partials: partials} ->
            import FuManchu.Util

            partials = stringify_keys(partials)

            fn context ->
              Enum.join(unquote(children))
            end.(stringify_keys(context))
          end
        end

        {:ok, quoted_fun}
    end
  end

  # Include text, whitespace and newlines as strings
  def generate({type, text, _line, _col})
      when type in [:text, :whitespace, :newline] do
    text
  end

  # Find variables in the context map, convert the result to a string and
  # encode it.
  def generate({:variable, variable, _line, _col}) do
    quote do
      context
      |> access(unquote(variable))
      |> to_string
      |> encode_html_entities
    end
  end

  # Similar to a variable but the value is not escaped.
  def generate({:unescaped_variable, variable, _line, _col}) do
    quote do
      context
      |> access(unquote(variable))
      |> to_string
    end
  end

  # First, generate expressions for the part of the template wrapped by the
  # section. Then, create an IIFE that passes in the newly unnested context and
  # renders the wrapped template. Before rendering the template we check the
  # truthiness of the context and return an empty string if false.
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

  # Similar to generating a section but we take the inverse of the truthiness
  # check when rendering.
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

  # Generate a partial without indentation.
  def generate({:partial, name, line, col}) do
    generate({:partial, name, line, col, ""})
  end

  # Grab the partial out of the partial map, apply the indetation to each line
  # and render the template with the current context.
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
