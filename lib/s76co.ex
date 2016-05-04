defmodule S76co do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(__MODULE__, [], function: :run),
      worker(S76co.Redis, [])
    ]

    opts = [strategy: :one_for_one]

    Supervisor.start_link(children, opts)
  end

  def run do
    Plug.Adapters.Cowboy.http S76co.Router, []
  end
end
