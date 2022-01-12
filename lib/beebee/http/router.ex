defmodule BeeBee.Http.Router do
  use Plug.Router

  alias BeeBee.ShortUrl

  plug Plug.RequestId
  plug Plug.Logger
  plug CORSPlug
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :match
  plug :dispatch, builder_opts()

  get "/" do
    conn
    |> resp(301, "You are being redirected.")
    |> put_resp_header("location", "https://www.system76.com")
    |> halt()
  end

  get "/_health" do
    {:ok, version} = :application.get_key(:beebee, :vsn)

    send_resp(conn, 200, Jason.encode!(%{version: List.to_string(version)}))
  end

  post "/_add" do
    case ShortUrl.add(conn.params) do
      {:ok, short_tag} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{short_tag: short_tag}))

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, Jason.encode!(%{error: reason}))
    end
  end

  get "/_stats" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(ShortUrl.stats()))
  end

  get "/:short_tag" do
    case ShortUrl.find(short_tag) do
      {:ok, full_url} ->
        conn
        |> put_resp_header("Location", full_url)
        |> send_resp(301, "")

      {:error, :not_found} ->
        send_resp(conn, 404, "Not Found")
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
