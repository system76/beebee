defmodule BeeBee.Redis do
  alias BeeBee.Redis.Server

  def start_link(state \\ nil), do: Server.start_link(state)

  def query(cmd), do: GenServer.call(Server, {:query, cmd})
end
