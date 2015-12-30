defmodule FuManchu.LexerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias FuManchu.Lexer

  test "scans a typical template" do
    template = """
    Hello {{name}}
    You have just won {{value}} dollars!
    {{#in_ca}}
    Well, {{taxed_value}} dollars, after taxes.
    {{/in_ca}}
    """

    tokens = [{:text, "Hello ", 1, 0},
              {:variable, "name", 1, 6},
              {:newline, "\n", 1, 14},

              {:text, "You have just won ", 2, 0},
              {:variable, "value", 2, 18},
              {:text, " dollars!", 2, 27},
              {:newline, "\n", 2, 36},

              {:section_begin, "in_ca", 3, 0},
              {:newline, "\n", 3, 10},

              {:text, "Well, ", 4, 0},
              {:variable, "taxed_value", 4, 6},
              {:text, " dollars, after taxes.", 4, 21},
              {:newline, "\n", 4, 43},

              {:section_end, "in_ca", 5, 0},
              {:newline, "\n", 5, 10}]

    assert Lexer.scan(template) == {:ok, tokens}
  end

  test "scans unescaped tags" do
    template = """
    * {{name}}
    * {{age}}
    * {{company}}
    * {{{company}}}
    """

    tokens = [{:text, "* ", 1, 0},
              {:variable, "name", 1, 2},
              {:newline, "\n", 1, 10},

              {:text, "* ", 2, 0},
              {:variable, "age", 2, 2},
              {:newline, "\n", 2, 9},

              {:text, "* ", 3, 0},
              {:variable, "company", 3, 2},
              {:newline, "\n", 3, 13},

              {:text, "* ", 4, 0},
              {:unescaped_variable, "company", 4, 2},
              {:newline, "\n", 4, 15}]

    assert Lexer.scan(template) == {:ok, tokens}
  end

  test "scans multi-line comments" do
    template = """
    What's for dinner? {{!
    Please say lasagna.
    }}
    """

    tokens = [{:text, "What's for dinner? ", 1, 0},
              {:comment, "Please say lasagna.", 1, 19},
              {:newline, "\n", 3, 2}]

    assert Lexer.scan(template) == {:ok, tokens}
  end

  test "raises error for missing tag end" do
    template = """
    What's for dinner? {{!
    Please say lasagna.
    """

    error = %Lexer.TokenMissingError{message: ~s[template:3:0: missing terminator: "}}" (for "{{" starting at line 1, column 19)]}

    assert Lexer.scan(template) == {:error, error}
  end

  test "raises error for unexpected tag begin" do
    template = """
    What's for dinner? {{!
    Please say lasagna.
    {{
    """

    error = %Lexer.TokenUnexpectedError{message: ~s[template:3:0: unexpected token: "{{"]}

    assert Lexer.scan(template) == {:error, error}
  end

  test "raises error for unexpected escaped tag begin" do
    template = """
    What's for dinner? {{{food}}
    """

    error = %Lexer.TokenUnexpectedError{message: ~s[template:1:26: unexpected token: "}}"]}

    assert Lexer.scan(template) == {:error, error}
  end

  test "warns for mismatched tag end" do
    template = """
    What's for dinner? {{food}}}
    """

    warning = capture_log(fn ->
      Lexer.scan(template)
    end)

    assert warning =~ ~s[template:1:25: tag end mismatched: "}}}"]
  end
end
