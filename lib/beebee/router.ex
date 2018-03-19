defmodule BeeBee.Router do
  use Plug.Router

  alias BeeBee.ShortenedURL

  plug Plug.Logger
  plug CORSPlug
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :match
  plug :dispatch

  post "/_add" do
    case ShortenedURL.add(conn.params) do
      {:ok, short_tag} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Poison.encode!(%{short_tag: short_tag}))
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, Poison.encode!(%{error: reason}))
    end
  end

  get "/_stats" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(ShortenedURL.stats))
  end

  get "/:short_tag" do
    case ShortenedURL.find(short_tag) do
      {:ok, full_url} ->
        conn
        |> put_resp_header("Location", full_url)
        |> send_resp(301, "")
      :not_found ->
        send_resp(conn, 404, "Not Found")
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
