defmodule BeeBee do
  @moduledoc """
  URL shortener for http://s76.co
  """
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  use Application

  @impl true
  def start(_type, _args) do
    storage_backend =
      Application.get_env(
        :beebee,
        :storage_backend,
        {BeeBee.Storage.Redis, []}
      )

    children = [
      storage_backend,
      {Plug.Cowboy, scheme: :http, plug: BeeBee.Router, options: [port: port()]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BeeBee.Supervisor]

    Logger.info("Starting BeeBee API on #{port()}...")

    Supervisor.start_link(children, opts)
  end

  defp port do
    :beebee
    |> Application.get_env(BeeBee.Router, port: 4000)
    |> Keyword.get(:port)
  end
end
