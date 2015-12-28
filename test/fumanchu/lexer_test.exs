defmodule FuManchu.LexerTest do
  use ExUnit.Case, async: true
  alias FuManchu.Lexer

  test "scans a typical template" do
    template = """
    Hello {{name}}
    You have just won {{value}} dollars!
    {{#in_ca}}
    Well, {{taxed_value}} dollars, after taxes.
    {{/in_ca}}
    """

    tokens = [{:text, "Hello ", 1},
              {:variable, "name", 1},
              {:newline, "\n", 1},

              {:text, "You have just won ", 2},
              {:variable, "value", 2},
              {:text, " dollars!", 2},
              {:newline, "\n", 2},

              {:section_begin, "in_ca", 3},
              {:newline, "\n", 3},

              {:text, "Well, ", 4},
              {:variable, "taxed_value", 4},
              {:text, " dollars, after taxes.", 4},
              {:newline, "\n", 4},

              {:section_end, "in_ca", 5},
              {:newline, "\n", 5}]

    assert Lexer.scan(template) == {:ok, tokens}
  end

  test "scans unescaped tags" do
    template = """
    * {{name}}
    * {{age}}
    * {{company}}
    * {{{company}}}
    """

    tokens = [{:text, "* ", 1},
              {:variable, "name", 1},
              {:newline, "\n", 1},

              {:text, "* ", 2},
              {:variable, "age", 2},
              {:newline, "\n", 2},

              {:text, "* ", 3},
              {:variable, "company", 3},
              {:newline, "\n", 3},

              {:text, "* ", 4},
              {:unescaped_variable, "company", 4},
              {:newline, "\n", 4}]

    assert Lexer.scan(template) == {:ok, tokens}
  end

  test "scans multi-line comments" do
    template = """
    What's for dinner? {{!
    Please say lasagna.
    }}
    """

    tokens = [{:text, "What's for dinner? ", 1},
              {:comment, "Please say lasagna.", 1},
              {:newline, "\n", 3}]

    assert Lexer.scan(template) == {:ok, tokens}
  end

  test "raises error for missing tag end" do
    template = """
    What's for dinner? {{!
    Please say lasagna.
    """

    error = %Lexer.TokenMissingError{message: ~s[template:3: missing terminator: "}}" (for "{{" starting at line 1)]}

    assert Lexer.scan(template) == {:error, error}
  end

  test "raises error for unexpected tag begin" do
    template = """
    What's for dinner? {{!
    Please say lasagna.
    {{
    """

    error = %Lexer.TokenUnexpectedError{message: ~s[template:3: unexpected token: "{{"]}

    assert Lexer.scan(template) == {:error, error}
  end
end
