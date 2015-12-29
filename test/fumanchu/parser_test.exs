defmodule FuManchu.ParserTest do
  use ExUnit.Case, async: true
  alias FuManchu.Parser

  test "parses tokens from a typical template" do
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

    ast = [{:text, "Hello ", 1, 0},
           {:variable, "name", 1, 6},
           {:newline, "\n", 1, 14},
           {:text, "You have just won ", 2, 0},
           {:variable, "value", 2, 18},
           {:text, " dollars!", 2, 27},
           {:newline, "\n", 2, 36},
           {:section, "in_ca", 3, 0, [
             {:text, "Well, ", 4, 0},
             {:variable, "taxed_value", 4, 6},
             {:text, " dollars, after taxes.", 4, 21},
             {:newline, "\n", 4, 43},
           ]}]

    assert Parser.parse(tokens) == {:ok, ast}
  end

  test "raises error for missing section end" do
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

              {:newline, "\n", 5, 10}]

    error = %Parser.TokenMissingError{message: ~s[template:5:10: missing section end: "{{/in_ca}}" (for "{{#in_ca}}" starting at line 3, column 0)]}

    assert Parser.parse(tokens) == {:error, error}
  end

  test "raises error for unrecognized token" do
    tokens = [{:text, "Hello ", 1, 0},
              {:variable, "name", 1, 6},
              {:newline, "\n", 1, 14},

              {:wut, "wut", 2, 0},

              {:newline, "\n", 2, 6}]

    error = %Parser.TokenUnrecognizedError{message: ~s[template:2:0: unrecognized token: :wut]}

    assert Parser.parse(tokens) == {:error, error}
  end
end
