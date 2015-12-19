defmodule FuManchu.ParserTest do
  use ExUnit.Case, async: true
  alias FuManchu.Parser

  test "parsing text" do
    ast = Parser.parse([text: 'Hello World!'])
    assert {:ok, [text: 'Hello World!']} = ast
  end

  test "parsing a variable" do
    ast = Parser.parse([text: 'Hello ', variable: 'planet'])
    assert {:ok, [text: 'Hello ', variable: 'planet']} = ast
  end

  test "parsing a section" do
    ast = Parser.parse([text: 'Shown.\n',
                        section_begin: 'person',
                        text: '\n  Never shown!\n',
                        section_end: 'person',
                        text: '\n'])
    assert {:ok, [{:text, 'Shown.\n'},
                  {:section, 'person', [
                    {:text, '\n  Never shown!\n'}]},
                  {:text, '\n'}]} = ast
  end

  test "parsing a section containing a variable" do
    ast = Parser.parse([section_begin: 'repo',
                        text: '\n  <b>',
                        variable: 'name',
                        text: '</b>\n',
                        section_end: 'repo',
                        text: '\n'])
    assert {:ok, [{:section, 'repo', [
                    {:text, '\n  <b>'},
                    {:variable, 'name'},
                    {:text, '</b>\n'}]},
                  {:text, '\n'}]} = ast
  end

  test "parsing nested sections" do
    ast = Parser.parse([section_begin: 'repo',
                        text: '\n  <b>',
                        section_begin: 'name',
                        text: 'fumanchu',
                        section_end: 'name',
                        text: '</b>\n',
                        section_end: 'repo',
                        text: '\n'])
    assert {:ok, [{:section, 'repo', [
                    {:text, '\n  <b>'},
                    {:section, 'name', [
                      {:text, 'fumanchu'}]},
                    {:text, '</b>\n'}]},
                  {:text, '\n'}]} = ast
  end
end
