defmodule BeeBee.Http.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__] ++ opts)
  end

  def init(:ok) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: BeeBee.Http.Router, options: [port: port()]}
    ]

    Logger.info("Starting Beebee API on #{port()}...")

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp port do
    :beebee
    |> Application.get_env(BeeBee.Http, port: 4000)
    |> Keyword.get(:port)
  end
end
