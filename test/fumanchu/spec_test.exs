defmodule FuManchu.SpecTest do
  use ExUnit.Case, async: true
  alias FuManchu

  @dest "test/support/mustache"
  @git "git@github.com:mustache/spec.git"
  @version "v1.1.3"

  unless File.dir?(@dest) do
    Mix.SCM.Git.checkout(git: @git, dest: @dest, tag: @version)
  end

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

      partials = Macro.escape(Map.get(test_case, "partials", %{}))
      data = Macro.escape(data)

      basename = Path.basename(spec_path, ".json")
      type = String.lstrip(basename, ?~)
      optional = String.starts_with?(basename, "~")

      @tag type: type
      @tag optional: optional

      test "#{name} - #{desc}" do
        actual = FuManchu.render(unquote(template), unquote(data), unquote(partials))
        assert actual == unquote(expected)
      end
    end
  end
end
