defmodule FuManchu.ParserTest do
  use ExUnit.Case, async: true
  alias FuManchu.Parser

  test "parses tokens from a typical template" do
    tokens = [{:text, "Hello ", 1},
              {:variable, "name", 1},
              {:text, "\n", 1},

              {:text, "You have just won ", 2},
              {:variable, "value", 2},
              {:text, " dollars!\n", 2},

              {:section_begin, "in_ca", 3},
              {:text, "\n", 3},

              {:text, "Well, ", 4},
              {:variable, "taxed_value", 4},
              {:text, " dollars, after taxes.\n", 4},

              {:section_end, "in_ca", 5},
              {:text, "\n", 5}]

    ast = [{:text, "Hello ", 1},
           {:variable, "name", 1},
           {:text, "\n", 1},
           {:text, "You have just won ", 2},
           {:variable, "value", 2},
           {:text, " dollars!\n", 2},
           {:section, "in_ca", 3, [
             {:text, "\n", 3},
             {:text, "Well, ", 4},
             {:variable, "taxed_value", 4},
             {:text, " dollars, after taxes.\n", 4}
           ]},
           {:text, "\n", 5}]

    assert Parser.parse(tokens) == {:ok, ast}
  end
end
