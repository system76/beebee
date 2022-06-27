defmodule BeeBee.RouterTest do
  @moduledoc false

  use ExUnit.Case

  import Plug.Test

  alias BeeBee.Router

  @process_name :redis_short_urls

  setup do
    Redix.command(@process_name, ["FLUSHDB"])
    on_exit(fn -> Redix.command(@process_name, ["FLUSHDB"]) end)
  end

  describe "GET /_health" do
    test "returns application health's response" do
      version = Application.spec(:beebee, :vsn) |> List.to_string()

      conn =
        :get
        |> conn("/_health")
        |> Router.call([])

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"version" => version}
    end
  end

  describe "GET /_stats" do
    test "returns statistics" do
      :post
      |> conn("/_add", %{"url" => "https://github.com"})
      |> Router.call([])

      conn =
        :get
        |> conn("/_stats")
        |> Router.call([])

      assert conn.status == 200
      assert [%{"count" => "0", "url" => "https://github.com"}] = Jason.decode!(conn.resp_body)
    end

    test "increments count" do
      :post
      |> conn("/_add", %{"url" => "https://github.com", "short_tag" => "test"})
      |> Router.call([])

      1..29
      |> Enum.each(fn _ ->
        :get
        |> conn("/test")
        |> Router.call([])
      end)

      conn =
        :get
        |> conn("/_stats")
        |> Router.call([])

      assert conn.status == 200
      assert [%{"count" => "29", "url" => "https://github.com"}] = Jason.decode!(conn.resp_body)
    end
  end

  describe "POST /_add" do
    test "creates a random short tag" do
      conn =
        :post
        |> conn("/_add", %{"url" => "https://github.com"})
        |> Router.call([])

      assert conn.status == 200
      assert %{"short_tag" => short_tag} = Jason.decode!(conn.resp_body)
      assert String.length(short_tag) == 8
    end

    test "creates a given short tag" do
      conn =
        :post
        |> conn("/_add", %{"url" => "https://github.com", "short_tag" => "banana"})
        |> Router.call([])

      assert conn.status == 200
      assert %{"short_tag" => "banana"} = Jason.decode!(conn.resp_body)
    end

    test "fails for existing short tag" do
      :post
      |> conn("/_add", %{"url" => "https://github.com", "short_tag" => "banana"})
      |> Router.call([])

      conn =
        :post
        |> conn("/_add", %{"url" => "https://github.com", "short_tag" => "banana"})
        |> Router.call([])

      assert conn.status == 422
      assert %{"errors" => ["Short tag already in use"]} = Jason.decode!(conn.resp_body)
    end
  end

  describe "Redirect" do
    test "short tag goes to the correct url" do
      :post
      |> conn("/_add", %{"url" => "https://github.com", "short_tag" => "banana"})
      |> Router.call([])

      conn =
        :get
        |> conn("/banana")
        |> Router.call([])

      assert conn.status == 301
      assert Enum.member?(conn.resp_headers, {"location", "https://github.com"})
    end

    test "root url goes to the correct location" do
      conn =
        :get
        |> conn("/")
        |> Router.call([])

      assert conn.status == 301
      assert Enum.member?(conn.resp_headers, {"location", "https://www.system76.com"})
    end
  end

  describe "API Error handling" do
    test "renders 404 for unknown endpoints" do
      conn =
        :get
        |> conn("/some/fakeurl")
        |> Router.call([])

      assert conn.status == 404
      assert Jason.decode!(conn.resp_body) == %{"errors" => ["Not Found"]}
    end
  end

  describe "Basic Authentication" do
    setup do
      Application.put_env(:beebee, BeeBee.Router, auth_username: "user", auth_password: "password")

      on_exit(fn ->
        Application.delete_env(:beebee, BeeBee.Router)
      end)
    end

    test "blocks unauthenticated add" do
      conn =
        :post
        |> conn("/_add", %{"url" => "https://github.com"})
        |> Router.call([])

      assert conn.status == 401
    end

    test "allows authenticated add" do
      encoded_credentials = Plug.BasicAuth.encode_basic_auth("user", "password")

      conn =
        :post
        |> conn("/_add", %{"url" => "https://github.com"})
        |> Plug.Conn.put_req_header("authorization", encoded_credentials)
        |> Router.call([])

      assert conn.status == 200
      assert %{"short_tag" => short_tag} = Jason.decode!(conn.resp_body)
      assert String.length(short_tag) == 8
    end

    test "blocks unauthenticated statistics" do
      conn =
        :get
        |> conn("/_stats")
        |> Router.call([])

      assert conn.status == 401
    end

    test "blocks bypass attempt" do
      conn =
        :get
        |> conn("/_stats/")
        |> Router.call([])

      assert conn.status == 401
    end

    test "blocks another bypass attempt" do
      conn =
        :get
        |> conn("///_stats///")
        |> Router.call([])

      assert conn.status == 401
    end

    test "allows authenticated statistics" do
      encoded_credentials = Plug.BasicAuth.encode_basic_auth("user", "password")

      :post
      |> conn("/_add", %{"url" => "https://github.com"})
      |> Plug.Conn.put_req_header("authorization", encoded_credentials)
      |> Router.call([])

      conn =
        :get
        |> conn("/_stats")
        |> Plug.Conn.put_req_header("authorization", encoded_credentials)
        |> Router.call([])

      assert conn.status == 200
      assert [%{"count" => "0", "url" => "https://github.com"}] = Jason.decode!(conn.resp_body)
    end

    test "allows unauthenticated redirect" do
      encoded_credentials = Plug.BasicAuth.encode_basic_auth("user", "password")

      :post
      |> conn("/_add", %{"url" => "https://github.com", "short_tag" => "banana"})
      |> Plug.Conn.put_req_header("authorization", encoded_credentials)
      |> Router.call([])

      conn =
        :get
        |> conn("/banana")
        |> Router.call([])

      assert conn.status == 301
      assert Enum.member?(conn.resp_headers, {"location", "https://github.com"})
    end

    test "allows unauthenticated health check" do
      version = Application.spec(:beebee, :vsn) |> List.to_string()

      conn =
        :get
        |> conn("/_health")
        |> Router.call([])

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"version" => version}
    end
  end
end
