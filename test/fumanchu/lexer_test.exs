defmodule FuManchu.LexerTest do
  use ExUnit.Case, async: true
  alias FuManchu.Lexer

  test "lexing text" do
    source = "Hello World!"
    tokens = Lexer.tokenize(source)
    assert {:ok, [text: 'Hello World!']} = tokens
  end

  test "lexing a variable" do
    source = "Hello {{planet}}"
    tokens = Lexer.tokenize(source)
    assert {:ok, [text: 'Hello ', variable: 'planet']} = tokens
  end

  test "lexing an unescaped variable" do
    source = "Hello {{{planet}}}"
    tokens = Lexer.tokenize(source)
    assert {:ok, [text: 'Hello ', unescaped_variable: 'planet']} = tokens
  end

  test "lexing an unescaped variable (& prefix)" do
    source = "Hello {{& planet}}"
    tokens = Lexer.tokenize(source)
    assert {:ok, [text: 'Hello ', unescaped_variable: 'planet']} = tokens
  end

  test "lexing a section" do
    source = """
    Shown.
    {{#person}}
      Never shown!
    {{/person}}
    """

    tokens = Lexer.tokenize(source)

    assert {:ok, [text: 'Shown.\n',
                  section_begin: 'person',
                  text: '\n  Never shown!\n',
                  section_end: 'person',
                  text: '\n']} = tokens
  end

  test "lexing a section containing a variable" do
    source = """
    {{#repo}}
      <b>{{name}}</b>
    {{/repo}}
    """

    tokens = Lexer.tokenize(source)

    assert {:ok, [section_begin: 'repo',
                  text: '\n  <b>',
                  variable: 'name',
                  text: '</b>\n',
                  section_end: 'repo',
                  text: '\n']} = tokens
  end

  test "lexing a comment" do
    source = "<h1>Today{{! ignore me}}.</h1>"
    tokens = Lexer.tokenize(source)
    assert {:ok, [text: '<h1>Today',
                  comment: 'ignore me',
                  text: '.</h1>']} = tokens
  end

  test "lexing a partial" do
    source = """
    <h2>Names</h2>
    {{#names}}
      {{> user}}
    {{/names}}
    """

    tokens = Lexer.tokenize(source)

    assert {:ok, [text: '<h2>Names</h2>\n',
                  section_begin: 'names',
                  text: '\n  ',
                  partial: 'user',
                  text: '\n',
                  section_end: 'names',
                  text: '\n']} = tokens
  end
end
