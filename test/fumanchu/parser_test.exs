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

    ast = [{:text, "Hello "},
           {:variable, "name"},
           {:text, "\n"},
           {:text, "You have just won "},
           {:variable, "value"},
           {:text, " dollars!\n"},
           {:section, "in_ca", [
             {:text, "\n"},
             {:text, "Well, "},
             {:variable, "taxed_value"},
             {:text, " dollars, after taxes.\n"}
           ]},
           {:text, "\n"}]

    assert Parser.parse(tokens) == {:ok, ast}
  end
end
