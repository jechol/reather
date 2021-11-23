defmodule Defr.MixProject do
  use Mix.Project

  @version "0.4.0"

  def project do
    [
      app: :defr,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      description: "Helper for Witchcraft's Reader monad",
      source_url: "https://github.com/trevorite/defr",
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
      {:ex_doc, "~> 0.25.0", only: :dev, runtime: false},
      {:algae, git: "https://github.com/jechol/algae.git", override: true},
      {:quark, git: "https://github.com/jechol/quark.git", override: true},
      {:type_class, git: "https://github.com/jechol/type_class.git", override: true},
      # Maintain until PR is merged. (https://github.com/witchcrafters/witchcraft/pull/83)
      {:witchcraft, git: "https://github.com/jechol/witchcraft.git", override: true}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/trevorite/defr"},
      maintainers: ["Jechol Lee(mr.trevorite@gmail.com)"]
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "defr",
      canonical: "http://hexdocs.pm/defr",
      source_url: "https://github.com/trevorite/defr",
      extras: [
        "README.md"
      ]
    ]
  end
end
