defmodule FuManchu do
  alias FuManchu.Compiler

  def render(source, context \\ %{}, partials \\ %{}) do
    Compiler.compile(source).(%{context: context, partials: partials})
  end
end
