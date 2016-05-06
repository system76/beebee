defmodule BeeBee.Mixfile do
  use Mix.Project

  def project do
    [
      app: :beebee,
      version: "1.0.0",
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
      {:cowboy,       "~> 1.0"},
      {:plug,         "~> 1.1"},
      {:exredis,      ">= 0.2.4"},
      {:poison,       "~> 2.1"},
      {:exrm,         "~> 1.0", override: true},
      {:conform,      "~> 2.0", override: true},
      {:conform_exrm, "~> 1.0.0"},
      {:edeliver,     ">= 1.1.4"},
    ]
  end
end
