defmodule FuManchu.Mixfile do
  use Mix.Project

  def project do
    [app: :fumanchu,
     version: "0.11.0",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     description: "An (almost) spec-compliant Mustache parser written in Elixir"]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:poison, "~> 1.5.0", only: :test}]
  end
end
