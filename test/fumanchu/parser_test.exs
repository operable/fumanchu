defmodule FuManchu.ParserTest do
  use ExUnit.Case, async: true
  alias FuManchu.Parser

  test "parses tokens from a typical template" do
    tokens = [{:text, "Hello ", 1},
              {:tag_open, "{{", 1},
              {:tag_key, "name", 1},
              {:tag_close, "}}", 1},
              {:text, "\n", 1},

              {:text, "You have just won ", 2},
              {:tag_open, "{{", 2},
              {:tag_key, "value", 2},
              {:tag_close, "}}", 2},
              {:text, " dollars!\n", 2},

              {:tag_open, "{{", 3},
              {:tag_type, "#", 3},
              {:tag_key, "in_ca", 3},
              {:tag_close, "}}", 3},
              {:text, "\n", 3},

              {:text, "Well, ", 4},
              {:tag_open, "{{", 4},
              {:tag_key, "taxed_value", 4},
              {:tag_close, "}}", 4},
              {:text, " dollars, after taxes.\n", 4},

              {:tag_open, "{{", 5},
              {:tag_type, "/", 5},
              {:tag_key, "in_ca", 5},
              {:tag_close, "}}", 5},
              {:text, "\n", 5}]

    ast = [{:text, "Hello ", 1},
           {:variable, "name", 1},
           {:text, "\n", 1},
           {:text, "You have just won ", 2},
           {:variable, "value", 2},
           {:text, " dollars!\n", 2},
           {:section, "in_ca", 5, [
             {:text, "\n", 3},
             {:text, "Well, ", 4},
             {:variable, "taxed_value", 4},
             {:text, " dollars, after taxes.\n", 4}
           ]},
           {:text, "\n", 5}]

    assert Parser.parse(tokens) == {:ok, ast}
  end
end
