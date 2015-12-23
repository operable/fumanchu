defmodule FuManchu.TokenizerTest do
  use ExUnit.Case, async: true
  alias FuManchu.Tokenizer

  test "tokenizes a typical template" do
    template = """
    Hello {{name}}
    You have just won {{value}} dollars!
    {{#in_ca}}
    Well, {{taxed_value}} dollars, after taxes.
    {{/in_ca}}
    """

    tokens = [{:text, "Hello ", 1},
              {:tag_open, "{{", 1},
              {:tag_key, "name", 1},
              {:tag_close, "}}", 1},
              {:newline, "\n", 1},

              {:text, "You have just won ", 2},
              {:tag_open, "{{", 2},
              {:tag_key, "value", 2},
              {:tag_close, "}}", 2},
              {:text, " dollars!", 2},
              {:newline, "\n", 2},

              {:tag_open, "{{", 3},
              {:tag_type, "#", 3},
              {:tag_key, "in_ca", 3},
              {:tag_close, "}}", 3},
              {:newline, "\n", 3},

              {:text, "Well, ", 4},
              {:tag_open, "{{", 4},
              {:tag_key, "taxed_value", 4},
              {:tag_close, "}}", 4},
              {:text, " dollars, after taxes.", 4},
              {:newline, "\n", 4},

              {:tag_open, "{{", 5},
              {:tag_type, "/", 5},
              {:tag_key, "in_ca", 5},
              {:tag_close, "}}", 5},
              {:newline, "\n", 5}]

    assert Tokenizer.tokenize(template) == {:ok, tokens}
  end

  test "tokenizes unescaped tags" do
    template = """
    * {{name}}
    * {{age}}
    * {{company}}
    * {{{company}}}
    """

    tokens = [{:text, "* ", 1},
              {:tag_open, "{{", 1},
              {:tag_key, "name", 1},
              {:tag_close, "}}", 1},
              {:newline, "\n", 1},

              {:text, "* ", 2},
              {:tag_open, "{{", 2},
              {:tag_key, "age", 2},
              {:tag_close, "}}", 2},
              {:newline, "\n", 2},

              {:text, "* ", 3},
              {:tag_open, "{{", 3},
              {:tag_key, "company", 3},
              {:tag_close, "}}", 3},
              {:newline, "\n", 3},

              {:text, "* ", 4},
              {:unescaped_tag_open, "{{{", 4},
              {:tag_key, "company", 4},
              {:unescaped_tag_close, "}}}", 4},
              {:newline, "\n", 4}]

    assert Tokenizer.tokenize(template) == {:ok, tokens}
  end

  test "tokenizes multi-line comments" do
    template = """
    What's for dinner? {{!
    Please say lasagna.
    }}
    """

    tokens = [{:text, "What's for dinner? ", 1},
              {:tag_open, "{{", 1},
              {:tag_type, "!", 1},
              {:newline, "\n", 1},
              {:tag_key, "Please say lasagna.", 2},
              {:newline, "\n", 2},
              {:tag_close, "}}", 3},
              {:newline, "\n", 3}]

    assert Tokenizer.tokenize(template) == {:ok, tokens}
  end
end
