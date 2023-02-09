defmodule BeeBee.Router do
  @moduledoc """
  HTTP router for BeeBee API endpoints.
  """
  require Logger

  use Plug.Router
  use Plug.ErrorHandler

  alias BeeBee.ShortUrl
  alias Plug.Conn.Status

  @secured_paths ~w(_add _update _delete _stats)

  plug Plug.RequestId
  plug LoggerJSON.Plug, metadata_formatter: LoggerJSON.Plug.MetadataFormatters.DatadogLogger
  plug CORSPlug
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :optional_basic_auth
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
        json_resp(conn, 422, %{errors: [reason]})
    end
  end

  put "/_update" do
    case ShortUrl.update(conn.params) do
      {:ok, short_tag, url} ->
        json_resp(conn, 200, %{short_tag: short_tag, url: url})

      {:error, reason} ->
        json_resp(conn, 422, %{errors: [reason]})
    end
  end

  delete "/_delete/:short_tag" do
    case ShortUrl.delete(short_tag) do
      :ok ->
        # pass no status or body gets a 204
        json_resp(conn)

      {:error, reason} ->
        json_resp(conn, 422, %{errors: [reason]})
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
        json_resp(conn, 404)
    end
  end

  match _ do
    json_resp(conn, 404)
  end

  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    formatted_reason = Exception.format(kind, reason)
    formatted_stack = Exception.format_stacktrace(stack)

    Logger.error(
      "Unexpected error handling API call" <>
        " method=#{conn.method}, path=#{conn.request_path}",
      kind: kind,
      reason: formatted_reason,
      stacktrace: formatted_stack
    )

    json_resp(conn, conn.status, %{errors: [Status.reason_phrase(conn.status)]})
  end

  defp redirect(conn, to_url, status \\ 301) do
    conn
    |> resp(status, "You are being redirected.")
    |> put_resp_header("location", to_url)
    |> halt()
  end

  defp json_resp(conn) do
    conn
    |> put_resp_content_type("application/json")
    # returns status 204
    |> send_resp(:no_content, "")
    |> halt()
  end

  defp json_resp(conn, status) when status in [404, :not_found] do
    body = %{errors: [Status.reason_phrase(404)]}
    json_resp(conn, status, body)
  end

  defp json_resp(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
    |> halt()
  end

  defp optional_basic_auth(conn, _opts) do
    username = Application.get_env(:beebee, BeeBee.Router)[:auth_username]
    password = Application.get_env(:beebee, BeeBee.Router)[:auth_password]

    if is_secured?(conn.path_info, username, password) do
      Plug.BasicAuth.basic_auth(conn, username: username, password: password)
    else
      conn
    end
  end

  defp is_secured?([], _username, _password), do: false

  defp is_secured?([path | _], username, password) do
    path in @secured_paths && exists?(username) && exists?(password)
  end

  defp exists?(value) do
    value
    |> to_string()
    |> String.trim()
    |> Kernel.!=("")
  end
end
