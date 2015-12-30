defmodule FuManchu do
  alias FuManchu.Compiler

  @doc """
  Compiles the mustache template and calls it with the given context and
  partials.

  Context is passed in as a list or map with keys of strings or atoms and can
  be accessed like `{{variable}}`. Nested context can be used by wrapping part
  of the template in a section: `{{#users}} Name: {{name}} {{/users}}`. The
  entire context will still be available in nested sections, but keys from the
  current level of nesting will take precedence.  If a bare list is passed in,
  you must use `{{#.}}{{/.}}` to iterate over the list.

      iex> FuManchu.render!("Hello {{planet}}", %{planet: "World!"})
      "Hello World!"

      iex> FuManchu.render!("My favorite colors:{{#.}} {{.}}{{/.}}",
      iex>                  ["red", "blue", "green"])
      "My favorite colors: red blue green"

  Partials are passed in as a map with names as keys and template strings as
  values and can be called like `{{> partial}}`. The current context and the
  map of partials are used when rendering each partial template, so recurring
  partials are possible.

      iex> FuManchu.render!("My favorite colors:{{#colors}} {{> display}}{{/colors}}",
      iex>                  %{colors: [%{name: "red", hex: "#ff0000"}, %{name: "blue", hex: "#0000ff"}]},
      iex>                  %{display: "{{name}} ({{hex}})"})
      "My favorite colors: red (#ff0000) blue (#0000ff)"

  For more in-depth examples and a full list of tags and rules take a look at
  the [Mustache Manual](https://mustache.github.io/mustache.5.html).
  """

  @spec render!(String.t, Map, Map) :: String.t
  def render!(source, context \\ %{}, partials \\ %{}) do
    Compiler.compile!(source).(%{context: context, partials: partials})
  end
end
