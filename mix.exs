defmodule Reather.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :reather,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ],
      package: package(),
      description: "Either transformed Reader (reather = REAder + eiTHER)",
      source_url: "https://github.com/jechol/reather",
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
      {:ex_doc, "~> 0.27.0", only: :dev, runtime: false},
      {:algae, "~> 1.3"},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jechol/reather"},
      maintainers: ["Jechol Lee(mr.jechol@gmail.com)"]
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "reather",
      canonical: "http://hexdocs.pm/reather",
      source_url: "https://github.com/jechol/reather",
      extras: [
        "README.md",
        "LICENSE.md"
      ]
    ]
  end
end
