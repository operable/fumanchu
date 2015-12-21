defmodule FuManchuTest do
  use ExUnit.Case, async: true
  doctest FuManchu

  test "render a template with context" do
    result = FuManchu.render("Hello {{planet}}", %{planet: "World!"})

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

    result = FuManchu.render(template, %{commands: ["operable:help", "operable:echo"]})

    assert result == """
    I know about these commands:


      * operable:help

      * operable:echo


    Try calling `operable:help COMMAND` to find out more.
    """
  end
end
