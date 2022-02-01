defmodule BeeBee.RouterTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Plug.Test

  alias BeeBee.Router

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
end
