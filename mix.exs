defmodule Hypex.Mixfile do
  use Mix.Project

  @version "1.1.0"
  @url_docs "http://hexdocs.pm/hypex"
  @url_github "https://github.com/zackehh/hypex"

  def project do
    [
      app: :hypex,
      name: "Hypex",
      description: "Fast HyperLogLog implementation for Elixir/Erlang",
      package: %{
        files: [
          "lib",
          "mix.exs",
          "LICENSE",
          "README.md"
        ],
        licenses: [ "MIT" ],
        links: %{
          "Docs" => @url_docs,
          "GitHub" => @url_github
        },
        maintainers: [ "Isaac Whitfield" ]
      },
      version: @version,
      elixir: "~> 1.1",
      deps: deps(),
      docs: [
        extras: [ "README.md" ],
        source_ref: "v#{@version}",
        source_url: @url_github
      ],
      test_coverage: [
        tool: ExCoveralls
      ],
      preferred_cli_env: [
        docs: :docs,
        bench: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.travis": :test
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      # Testing dependencies
      {:excoveralls, "~> 0.9", optional: true, only: [:dev, :test]},
      # Benchmarking dependencies
      {:benchee, "~> 0.13", optional: true, only: [:bench]},
      {:benchee_html, "~> 0.5", optional: true, only: [:bench]},
      # Documentation dependencies
      {:ex_doc, "~> 0.19", optional: true, only: [:docs]}
    ]
  end
end
