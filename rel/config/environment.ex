defmodule BeeBeeRelease.Config.Environment do
  def schema(), do: %{
    "REDIS_HOST" => [:exredis, :host],
    "REDIS_PORT" => [:exredis, :port],
    "REDIS_PASSWORD" => [:exredis, :password],
    "REDIS_DB" => [:exredis, :db],
    "REDIS_RECONNECT" => [:exredis, :reconnect],
    "REDIS_MAX_QUEUE" => [:exredis, :max_queue]
  }
end
