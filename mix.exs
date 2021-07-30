defmodule Defre.MixProject do
  use Mix.Project

  @version "1.2.1"

  def project do
    [
      app: :defre,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      description: "Unobtrusive Dependency Injector for Elixir",
      source_url: "https://github.com/jechol/defre",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.23.0", only: :dev, runtime: false},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}

      {:quark, git: "https://github.com/witchcrafters/quark.git", override: true},
      {:type_class, git: "https://github.com/witchcrafters/type_class.git", override: true},
      {:witchcraft, git: "https://github.com/jechol/witchcraft.git", override: true},
      {:algae, git: "https://github.com/witchcrafters/algae.git"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jechol/defre"},
      maintainers: ["Jechol Lee(mr.jechol@gmail.com)"]
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "defre",
      canonical: "http://hexdocs.pm/defre",
      source_url: "https://github.com/jechol/defre",
      extras: [
        "README.md"
      ]
    ]
  end
end
