defmodule BeeBee.Mixfile do
  use Mix.Project

  def project do
    [
      app: :beebee,
      version: "1.2.0",
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      compilers: Mix.compilers(),
      deps: deps(),
      default_release: :beebee,
      releases: [
        beebee: [
          include_erts: true,
          include_executables_for: [:unix],
          runtime_config_path: "config/runtime.exs"
        ]
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {BeeBee, []},
      # Specify extra applications you'll use from Erlang/Elixir
      extra_applications: [:logger]
    ]
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
      {:cors_plug, "~> 2.0"},
      {:jason, "~> 1.3"},
      {:logger_json, "~> 4.3"},
      {:plug, "~> 1.12"},
      {:plug_cowboy, "~> 2.5"},
      {:redix, "~> 1.0.0"},
      # Development and testing dependencies
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: [:test, :dev]}
    ]
  end
end
