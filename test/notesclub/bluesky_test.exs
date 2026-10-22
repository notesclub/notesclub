defmodule Notesclub.BlueskyTest do
  use ExUnit.Case

  import Notesclub.HTTPStub
  import Plug.Conn

  alias Notesclub.Bluesky

  @moduletag :capture_log
  @moduletag app_env: [bluesky_handle: "notes.test", bluesky_password: "test-password"]
  setup :setup_http

  test "authenticates and posts Unicode links and hashtags with correct byte offsets" do
    message = "📚 https://notes.club/book. #ElixirLang #café https://."

    Req.Test.stub(__MODULE__, fn conn ->
      case conn.request_path do
        "/xrpc/com.atproto.server.createSession" ->
          assert read_json(conn) == %{"identifier" => "notes.test", "password" => "test-password"}
          Req.Test.json(conn, %{accessJwt: "test-token"})

        "/xrpc/com.atproto.repo.createRecord" ->
          assert get_req_header(conn, "authorization") == ["Bearer test-token"]
          body = read_json(conn)
          assert body["repo"] == "notes.test"
          assert body["collection"] == "app.bsky.feed.post"
          record = body["record"]
          assert record["text"] == message
          assert {:ok, _, 0} = DateTime.from_iso8601(record["createdAt"])
          assert length(record["facets"]) == 3

          assert Enum.map(record["facets"], fn facet ->
                   %{"byteStart" => start, "byteEnd" => stop} = facet["index"]
                   binary_part(message, start, stop - start)
                 end) == ["https://notes.club/book", "#ElixirLang", "#café"]

          assert hd(record["facets"])["features"] == [
                   %{
                     "$type" => "app.bsky.richtext.facet#link",
                     "uri" => "https://notes.club/book"
                   }
                 ]

          Req.Test.json(conn, %{uri: "at://posted"})
      end
    end)

    assert {:ok, "Post created successfully"} = Bluesky.post(message)
  end

  test "posts plain text without facets" do
    Req.Test.stub(__MODULE__, fn conn ->
      if String.ends_with?(conn.request_path, "createSession") do
        Req.Test.json(conn, %{accessJwt: "test-token"})
      else
        refute Map.has_key?(read_json(conn)["record"], "facets")
        Req.Test.json(conn, %{})
      end
    end)

    assert {:ok, _} = Bluesky.post("Hello")
  end

  @tag app_env: [bluesky_handle: nil, bluesky_password: nil]
  test "rejects missing credentials without making a request" do
    assert {:error, "Bluesky credentials not configured"} = Bluesky.post("Hello")
  end

  test "returns authentication and transport failures" do
    Req.Test.stub(
      __MODULE__,
      &Req.Test.json(put_status(&1, 401), %{error: "invalid credentials"})
    )

    assert {:error, reason} = Bluesky.post("Hello")
    assert reason =~ "Authentication failed with status 401"

    Req.Test.stub(__MODULE__, &Req.Test.transport_error(&1, :timeout))
    assert {:error, reason} = Bluesky.post("Hello")
    assert reason =~ "HTTP request failed"
  end

  test "returns post creation failures after authentication" do
    for response <- [:rejected, :timeout] do
      Req.Test.stub(__MODULE__, fn conn ->
        cond do
          String.ends_with?(conn.request_path, "createSession") ->
            Req.Test.json(conn, %{accessJwt: "test-token"})

          response == :rejected ->
            Req.Test.json(put_status(conn, 400), %{error: "invalid post"})

          true ->
            Req.Test.transport_error(conn, :timeout)
        end
      end)

      assert {:error, reason} = Bluesky.post("Hello")

      assert reason =~
               if(response == :rejected,
                 do: "Post creation failed with status 400",
                 else: "HTTP request failed"
               )
    end
  end
end
