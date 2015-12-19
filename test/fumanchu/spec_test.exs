defmodule FuManchu.SpecTest do
  use ExUnit.Case, async: true
  alias FuManchu

  @dest "test/support/mustache"
  @git "git@github.com:mustache/spec.git"
  @version "v1.1.3"

  Mix.SCM.Git.checkout(git: @git, dest: @dest, tag: @version)
  specs_glob = Path.join([@dest, "specs", "*.json"])

  for spec_path <- Path.wildcard(specs_glob) do
    test_cases = spec_path
    |> File.read!
    |> Poison.decode!
    |> Map.get("tests", [])

    for test_case <- test_cases do
      %{"name" => name,
        "desc" => desc,
        "data" => data,
        "template" => template,
        "expected" => expected} = test_case

      data = Macro.escape(data)

      test "#{name} - #{desc}" do
        actual = FuManchu.render(unquote(template), unquote(data))
        assert actual == unquote(expected)
      end
    end
  end
end
