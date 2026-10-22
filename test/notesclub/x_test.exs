defmodule Notesclub.XTest do
  use Notesclub.DataCase

  import Notesclub.HTTPStub
  import Plug.Conn

  alias Notesclub.X
  alias Notesclub.X.XAPI
  alias Notesclub.X.XTokens

  setup :setup_http

  test "exchanges a PKCE code, persists tokens, and uses the stored access token" do
    Req.Test.stub(__MODULE__, fn conn ->
      case conn.request_path do
        "/2/oauth2/token" ->
          params = URI.decode_query(conn.query_string)
          assert params["code"] == "authorization-code"
          assert params["code_verifier"] == "verifier"
          assert params["redirect_uri"] == "https://localhost:4000/callback"

          assert get_req_header(conn, "authorization") == [
                   "Basic " <> Base.encode64("123:secret")
                 ]

          Req.Test.json(conn, %{access_token: "access", refresh_token: "refresh"})

        "/2/tweets" ->
          assert read_json(conn) == %{"text" => "A notebook"}
          assert get_req_header(conn, "authorization") == ["Bearer access"]
          Req.Test.json(put_status(conn, 201), %{data: %{id: "tweet-id"}})
      end
    end)

    assert {:ok, "access"} = X.authenticate("authorization-code", "verifier")
    assert %{access_token: "access", refresh_token: "refresh"} = XTokens.get_latest_token()
    assert {:ok, %{body: %{"data" => %{"id" => "tweet-id"}}}} = X.post("A notebook")
    assert %DateTime{} = XTokens.get_latest_token().last_used_at
  end

  test "refreshes an expired token and retries the post with the new token" do
    {:ok, token} = XTokens.create_token(%{access_token: "expired", refresh_token: "refresh"})

    Req.Test.stub(__MODULE__, fn conn ->
      case {conn.request_path, get_req_header(conn, "authorization")} do
        {"/2/tweets", ["Bearer expired"]} ->
          Req.Test.json(put_status(conn, 401), %{error: "expired"})

        {"/2/oauth2/token", _} ->
          {:ok, body, _} = read_body(conn)

          assert URI.decode_query(body) == %{
                   "grant_type" => "refresh_token",
                   "refresh_token" => "refresh",
                   "client_id" => "123"
                 }

          Req.Test.json(conn, %{access_token: "new-access", refresh_token: "new-refresh"})

        {"/2/tweets", ["Bearer new-access"]} ->
          Req.Test.json(put_status(conn, 201), %{data: %{id: "new-tweet"}})
      end
    end)

    assert {:ok, %{body: %{"data" => %{"id" => "new-tweet"}}}} = X.post("A notebook")

    assert %{id: id, access_token: "new-access", refresh_token: "new-refresh"} =
             XTokens.get_latest_token()

    assert id == token.id
  end

  test "returns an error when there is no stored token or no refresh token" do
    assert {:error, :no_token_available} = X.post("A notebook")
    {:ok, _} = XTokens.create_token(%{access_token: "expired"})
    Req.Test.stub(__MODULE__, &Req.Test.json(put_status(&1, 401), %{error: "expired"}))
    assert {:error, :no_refresh_token} = X.post("A notebook")
  end

  test "propagates token exchange and refresh transport failures" do
    Req.Test.stub(__MODULE__, &Req.Test.transport_error(&1, :timeout))
    assert {:error, %Req.TransportError{reason: :timeout}} = X.authenticate("code", "verifier")
    assert XTokens.get_latest_token() == nil
    {:ok, _} = XTokens.create_token(%{access_token: "expired", refresh_token: "refresh"})
    assert {:error, %Req.TransportError{reason: :timeout}} = X.post("A notebook")
  end

  test "does not persist invalid tokens returned by the API" do
    Req.Test.stub(__MODULE__, &Req.Test.json(&1, %{}))
    assert {:error, changeset} = X.authenticate("code", "verifier")
    assert "can't be blank" in errors_on(changeset).access_token
    assert XTokens.get_latest_token() == nil
  end

  test "reports posting errors and validates token changes" do
    Req.Test.stub(__MODULE__, &Req.Test.json(put_status(&1, 403), %{error: "forbidden"}))
    assert {:error, %{status: 403}} = XAPI.post("A notebook", "access")
    assert {:error, changeset} = XTokens.create_token()
    assert "can't be blank" in errors_on(changeset).access_token
  end
end
