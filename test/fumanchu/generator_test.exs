defmodule FuManchu.GeneratorTest do
  use ExUnit.Case, async: true
  alias FuManchu.Generator

  test "generating text" do
    {:ok, quoted_fun} = Generator.generate([{:text, "Hello World!", 1, 0}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{context: %{}, partials: %{}}) == "Hello World!"
  end

  test "generating a variable" do
    {:ok, quoted_fun} = Generator.generate([{:text, "Hello ", 1, 0}, {:variable, "planet", 1, 6}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{context: %{planet: "World!"}, partials: %{}}) == "Hello World!"
  end

  test "generating a section containing a variable" do
    {:ok, quoted_fun} = Generator.generate([{:section, "repo", 1, 0, [
                                       {:newline, "\n  ", 1, 9},
                                       {:text, "<b>", 2, 0},
                                       {:section, "name", 2, 3, [
                                         {:text, "fumanchu", 2, 12}]},
                                       {:text, "</b>", 2, 20},
                                       {:newline, "\n", 2, 24}]},
                                     {:newline, "\n", 3, 0}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{context: %{repo: true, name: true}, partials: %{}}) == """
    \n  <b>fumanchu</b>\n
    """
  end

  test "generating a section used for iteration" do
    {:ok, quoted_fun} = Generator.generate([{:section, "commands", 1, 0, [
                                       {:variable, ".", 1, 14},
                                       {:newline, "\n", 1, 20}]}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{context: %{commands: ["operable:echo", "operable:help"]}, partials: %{}}) == """
    operable:echo
    operable:help
    """
  end

  test "generating a section used for iteration by key" do
    {:ok, quoted_fun} = Generator.generate([{:text, "\"", 1, 0},
                                     {:section, "list", 1, 1, [
                                       {:variable, "item", 1, 10}]},
                                     {:text, "\"", 1, 18}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{context: %{list: [%{item: 1}, %{item: 2}, %{item: 3}]}, partials: %{}}) == "\"123\""
  end

  test "generating code for an unknown ast" do
    ast = [{:text, "What's for dinner?", 1, 0},
           {:newline, "\n", 1, 18},
           {:section, "is_lasagna", 2, 0, [
             {:wut, "wut", 2, 15}]}]

    error = %Generator.ASTNodeUnrecognizedError{message: ~s[template:2: unrecognized ast node: :wut]}

    assert Generator.generate(ast) == {:error, error}
  end
end
