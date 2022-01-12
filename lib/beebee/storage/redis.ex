defmodule BeeBee.Storage.Redis do
  @moduledoc """
  Redis storage backend for short URLs.
  """
  require Logger

  @behaviour BeeBee.ShortUrl

  @namespace "beebee"

  @process_name :redis_short_urls

  def child_spec(opts) do
    redis_config = Keyword.get(opts, :redis_config, [])

    children = [
      Supervisor.child_spec({Redix, Keyword.merge([name: @process_name], redis_config)},
        id: {Redix, @process_name}
      )
    ]

    # Spec for the supervisor that will supervise the Redix connections.
    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  @impl true
  def create(url, short_tag) do
    with {:ok, 0} <- Redix.command(@process_name, ["EXISTS", url_key(short_tag)]),
         {:ok, ["OK", "OK"]} <-
           Redix.pipeline(@process_name, [
             ["SET", url_key(short_tag), url],
             ["SET", count_key(short_tag), 0]
           ]) do
      {:ok, short_tag}
    else
      {:ok, 1} ->
        {:error, "Short tag already in use"}

      {:error, reason} ->
        Logger.error("Error creating data in Redis",
          url: url,
          short_tag: short_tag,
          reason: reason
        )

        {:error, "Server error"}
    end
  end

  @impl true
  def find(short_tag) do
    with {:ok, url} = response when is_binary(url) <-
           Redix.command(@process_name, ["GET", url_key(short_tag)]),
         {:ok, _count} <- Redix.command(@process_name, ["INCR", count_key(short_tag)]) do
      response
    else
      {:ok, nil} -> {:error, :not_found}
    end
  end

  @impl true
  def stats do
    Stream.resource(
      fn -> do_scan("0") end,
      &stream_scan(&1),
      fn _ -> :ok end
    )
    |> Stream.map(fn {_key, value} -> value end)
    |> Enum.group_by(&Map.get(&1, "short_tag"))
    |> Enum.map(fn
      {_st, [map1, map2]} -> Map.merge(map1, map2)
      {_st, [map1]} -> map1
    end)
  end

  defp url_key(short_tag), do: "#{@namespace}:#{short_tag}:url"

  defp count_key(short_tag), do: "#{@namespace}:#{short_tag}:count"

  defp stream_scan({[], "0"}), do: {:halt, nil}

  defp stream_scan({[], cursor}) do
    result = do_scan(cursor)

    stream_scan(result)
  end

  defp stream_scan({keys, cursor}), do: {keys, {[], cursor}}

  defp do_scan(cursor) do
    case Redix.command(@process_name, ["SCAN", cursor || 0, "MATCH", "#{@namespace}:*"]) do
      {:ok, [new_cursor, new_keys]} ->
        {normalize_stats(new_keys), new_cursor}

      error ->
        error
    end
  end

  defp normalize_stats(keys) do
    values = Redix.command!(@process_name, ["MGET"] ++ keys)

    keys
    |> Enum.zip(values)
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      [_, short_tag, type] = String.split(key, ":")

      Map.update(
        acc,
        short_tag,
        %{type => value, "short_tag" => short_tag},
        &Map.merge(&1, %{type => value})
      )
    end)
  end
end
