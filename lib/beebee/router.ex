defmodule BeeBee.Router do
  @moduledoc """
  HTTP router for BeeBee API endpoints.
  """
  use Plug.Router

  alias BeeBee.ShortUrl

  plug Plug.RequestId

  plug LoggerJSON.Plug,
    metadata_formatter: LoggerJSON.Plug.MetadataFormatters.DatadogLogger

  plug CORSPlug
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :match
  plug :dispatch, builder_opts()

  get "/" do
    redirect(conn, "https://www.system76.com")
  end

  get "/_health" do
    {:ok, version} = :application.get_key(:beebee, :vsn)

    json_resp(conn, 200, %{version: List.to_string(version)})
  end

  post "/_add" do
    case ShortUrl.create(conn.params) do
      {:ok, short_tag} ->
        json_resp(conn, 200, %{short_tag: short_tag})

      {:error, reason} ->
        json_resp(conn, 422, %{error: reason})
    end
  end

  get "/_stats" do
    json_resp(conn, 200, ShortUrl.stats())
  end

  get "/:short_tag" do
    case ShortUrl.find(short_tag) do
      {:ok, full_url} ->
        redirect(conn, full_url)

      {:error, :not_found} ->
        send_resp(conn, 404, "Not Found")
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp redirect(conn, to_url, status \\ 301) do
    conn
    |> resp(status, "You are being redirected.")
    |> put_resp_header("location", to_url)
    |> halt()
  end

  defp json_resp(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
