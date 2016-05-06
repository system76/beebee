defmodule BeeBee.ShortenedURL do
  alias BeeBee.{Redis, ShortTag}

  @namespace "beebee"

  def add(%{"url" => url, "short_tag" => short_tag}) do
    url_key = "#{@namespace}:#{short_tag}:url"
    count_key = "#{@namespace}:#{short_tag}:count"

    case Redis.query(["EXISTS", url_key]) do
      "0" ->
        Redis.query(["SET", url_key, url])
        Redis.query(["SET", count_key, "0"])

        {:ok, short_tag}
      "1" ->
        {:error, "Short tag already in use"}
      _ ->
        {:error, "Server error"}
    end
  end

  def add(%{"url" => url}) do
    add(%{"url" => url, "short_tag" => ShortTag.generate})
  end

  def find(short_tag) do
    url_key = "#{@namespace}:#{short_tag}:url"
    count_key = "#{@namespace}:#{short_tag}:count"

    case Redis.query(["GET", url_key]) do
      :undefined ->
        :not_found
      url ->
        Redis.query(["INCR", count_key])
        {:ok, url}
    end
  end

  def stats do
    scan_keys
    |> Enum.reduce(%{}, fn key, memo ->
      [_, short_tag, type] = String.split key, ":"
      value = Redis.query(["GET", key])

      memo = Map.put_new(memo, short_tag, %{})
      put_in memo, [short_tag, type], value
    end)
    |> Enum.map(fn {short_tag, data} ->
      Dict.put data, "short_tag", short_tag
    end)
  end

  defp scan_keys, do: scan_keys(nil, [])

  defp scan_keys("0", keys), do: Enum.uniq(keys)
  defp scan_keys(cursor, keys) do
    [new_cursor, new_keys] = Redis.query(["SCAN", (cursor || 0), "MATCH", "#{@namespace}:*"])

    scan_keys(new_cursor, keys ++ new_keys)
  end
end
