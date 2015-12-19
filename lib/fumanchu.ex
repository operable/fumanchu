defmodule FuManchu do
  alias FuManchu.Compiler

  def render(source, bindings \\ %{}) do
    Compiler.compile(source).(bindings)
  end
end
