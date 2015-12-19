defmodule FuManchu.GeneratorTest do
  use ExUnit.Case, async: true
  alias FuManchu.Generator

  test "generating text" do
    quoted_fun = Generator.generate([text: 'Hello World!'])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.([]) == "Hello World!"
  end

  test "generating a variable" do
    quoted_fun = Generator.generate([text: 'Hello ', variable: 'planet'])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{planet: "World!"}) == "Hello World!"
  end

  test "generating a section containing a variable" do
    quoted_fun = Generator.generate([{:section, 'repo', [
                                       {:text, '\n  <b>'},
                                       {:section, 'name', [
                                         {:text, 'fumanchu'}]},
                                       {:text, '</b>\n'}]},
                                     {:text, '\n'}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{repo: true, name: true}) == """
    \n  <b>fumanchu</b>\n
    """
  end

  test "generating a section used for iteration" do
    quoted_fun = Generator.generate([{:section, 'commands', [
                                       {:variable, '.'},
                                       {:text, '\n'}]}])
    {fun, []} = Code.eval_quoted(quoted_fun)
    assert fun.(%{commands: ["operable:echo", "operable:help"]}) == """
    operable:echo
    operable:help
    """
  end
end
