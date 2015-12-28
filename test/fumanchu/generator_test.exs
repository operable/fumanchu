defmodule FuManchu.GeneratorTest do
  use ExUnit.Case, async: true
  alias FuManchu.Generator

  test "generating text" do
    {:ok, quoted_fun} = Generator.generate([{:text, "Hello World!", 1}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{context: %{}, partials: %{}}) == "Hello World!"
  end

  test "generating a variable" do
    {:ok, quoted_fun} = Generator.generate([{:text, "Hello ", 1}, {:variable, ["planet"], 1}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{context: %{planet: "World!"}, partials: %{}}) == "Hello World!"
  end

  test "generating a section containing a variable" do
    {:ok, quoted_fun} = Generator.generate([{:section, ["repo"], 3, [
                                       {:text, "\n  ", 1},
                                       {:text, "<b>", 2},
                                       {:section, ["name"], 2, [
                                         {:text, "fumanchu", 2}]},
                                       {:text, "</b>\n", 2}]},
                                     {:text, "\n", 3}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{context: %{repo: true, name: true}, partials: %{}}) == """
    \n  <b>fumanchu</b>\n
    """
  end

  test "generating a section used for iteration" do
    {:ok, quoted_fun} = Generator.generate([{:section, ["commands"], 1, [
                                       {:variable, ".", 1},
                                       {:text, "\n", 1}]}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{context: %{commands: ["operable:echo", "operable:help"]}, partials: %{}}) == """
    operable:echo
    operable:help
    """
  end

  test "generating a section used for iteration by key" do
    {:ok, quoted_fun} = Generator.generate([{:text, "\"", 1},
                                     {:section, ["list"], 1, [
                                       {:variable, ["item"], 1}]},
                                     {:text, "\"", 1}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{context: %{list: [%{item: 1}, %{item: 2}, %{item: 3}]}, partials: %{}}) == "\"123\""
  end
end
