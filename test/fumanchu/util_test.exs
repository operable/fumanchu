defmodule FuManchu.UtilTest do
  use ExUnit.Case, async: true
  alias FuManchu.Util

  test "stringifying keys of shallow map" do
    actual = Util.stringify_keys(%{foo: "bar",
                                   baz: :qux})

    assert %{"foo" => "bar",
             "baz" => :qux} = actual
  end

  test "stringifying keys of a deep map" do
    actual = Util.stringify_keys(%{foo: [%{bar: :rag}],
                                   baz: %{qux: "nork"}})

    assert %{"foo" => [%{"bar" => :rag}],
             "baz" => %{"qux" => "nork"}} = actual
  end

  test "stringifying a list of maps" do
    actual = Util.stringify_keys([%{foo: "bar"},
                                  %{baz: :qux}])

    assert [%{"foo" => "bar"},
            %{"baz" => :qux}] = actual
  end

  test "encoding a string including html entities" do
    actual  = Util.encode_html_entities("& \" < >")

    assert "&amp; &quot; &lt; &gt;" == actual
  end

  test "access a map key" do
    assert Util.access(%{"a" => "b"}, ["a"]) == "b"
  end

  test "access current context" do
    assert Util.access(%{"a" => "b"}, ".") == %{"a" => "b"}
  end

  test "access something that doesn't exist" do
    assert Util.access(%{"a" => "b"}, ["a", "b", "c"]) == ""
  end
end
