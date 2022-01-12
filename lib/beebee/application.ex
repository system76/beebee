defmodule BeeBee.Application do
  @moduledoc false

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  use Application

  @impl true
  def start(_type, _args) do
    storage_backend =
      Application.get_env(
        :beebee,
        :storage_backend,
        {BeeBee.ShortUrls.Redis, []}
      )

    children = [
      storage_backend,
      BeeBee.Http.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BeeBee.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
