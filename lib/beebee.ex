defmodule BeeBee do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(__MODULE__, [], function: :run),
      worker(BeeBee.Redis, [])
    ]

    opts = [strategy: :one_for_one]

    Supervisor.start_link(children, opts)
  end

  def run do
    Plug.Adapters.Cowboy.http BeeBee.Router, []
  end
end
