defmodule FuManchu do
  alias FuManchu.Compiler

  def render(source, context \\ %{}) do
    Compiler.compile(source).(context)
  end
end
