defmodule FuManchu do
  alias FuManchu.Compiler

  @spec render!(String.t, map, map) :: String.t
  def render!(source, context \\ %{}, partials \\ %{}) do
    Compiler.compile!(source).(%{context: context, partials: partials})
  end
end
