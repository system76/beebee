defmodule BeeBee.Mixfile do
  use Mix.Project

  def project do
    [
      app: :beebee,
      version: "1.2.0",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {BeeBee, []},
      applications: [
        :cowboy,
        :plug,
        :logger,
        :exredis,
        :poison,
        :edeliver,
      ],
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
      {:cors_plug,    "~> 1.1"},
      {:cowboy,       "~> 1.0"},
      {:plug,         "~> 1.1"},
      {:exredis,      ">= 0.2.4"},
      {:poison,       "~> 2.1"},

      {:edeliver, "~> 1.4.5"},
      {:distillery, "~> 1.0.0", warn_missing: false},
      {:conform, "~> 2.2"},
    ]
  end
end
