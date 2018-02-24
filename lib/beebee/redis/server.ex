defmodule BeeBee.Redis.Server do
  use GenServer

  def start_link(state) do
    GenServer.start_link __MODULE__, state, name: __MODULE__
  end

  def init(_state), do: Exredis.start_link

  def terminate(_reason, conn), do: Exredis.stop(conn)

  def handle_call({:query, cmd}, _from, conn) do
    {:reply, Exredis.query(conn, cmd), conn}
  end
end
