defmodule FuManchuTest do
  use ExUnit.Case, async: true
  alias FuManchu.Lexer.TokenUnexpectedError

  doctest FuManchu

  test "render a template with context" do
    result = FuManchu.render!("Hello {{planet}}", %{planet: "World!"})

    assert result == "Hello World!"
  end

  test "render a template with iterable context" do
    template = """
    I know about these commands:

    {{#commands}}
      * {{.}}
    {{/commands}}

    Try calling `operable:help COMMAND` to find out more.
    """

    result = FuManchu.render!(template, %{commands: ["operable:help", "operable:echo"]})

    assert result == """
    I know about these commands:

      * operable:help
      * operable:echo

    Try calling `operable:help COMMAND` to find out more.
    """
  end

  test "render a template with a section followed by an inverse section" do
    template = """
    {{#command}}
      Your command is "{{command}}".
    {{/command}}
    {{^command}}
      Oops. Your command could not be found.
    {{/command}}
    """

    result = FuManchu.render!(template, %{command: "help"})

    assert result == """
      Your command is "help".
    """

    result = FuManchu.render!(template, %{})

    assert result == """
      Oops. Your command could not be found.
    """
  end

  test "raises an error if the template couldn't be compiled" do
    template = """
    I know about these commands:

    {{#commands}}
      * {{.}
    {{/commands}}

    Try calling `operable:help COMMAND` to find out more.
    """

    assert_raise TokenUnexpectedError, ~s[template:5:0: unexpected token: "{{"], fn ->
      FuManchu.render!(template, %{commands: ["operable:help", "operable:echo"]})
    end
  end
end
