defmodule NotesclubWeb.Plugs.RawUrlRedirectorTest do
  use NotesclubWeb.ConnCase

  alias NotesclubWeb.Plugs.RawUrlRedirector

  test "redirects to raw url when path ends in /raw" do
    # We can use the router to test this integration, or just test the plug with a proper conn.
    # Let's use build_conn() and manually invoke the plug.

    conn =
      build_conn()
      |> Map.put(:path_info, [
        "elixir-nx",
        "axon",
        "blob",
        "main",
        "notebooks",
        "vision",
        "mnist.livemd",
        "raw"
      ])
      |> Map.put(:request_path, "/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd/raw")
      |> RawUrlRedirector.call(%{})

    assert conn.halted

    assert redirected_to(conn) ==
             "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd"
  end

  test "ignores paths not ending in /raw" do
    conn =
      build_conn()
      |> Map.put(:path_info, ["some", "other", "path"])
      |> Map.put(:request_path, "/some/other/path")
      |> RawUrlRedirector.call(%{})

    refute conn.halted
  end

  test "ignores paths ending in /raw but not mappable to a github url" do
    # E.g. locally relative paths that don't match the structure expected by path_to_url
    # though path_to_url is quite lenient, let's try something weird
    # Paths.path_to_url/1 just prepends https://github.com if it doesn't have it, logic is loose.
    # But Urls.raw_url checks for github.com structure.

    # Let's try a path that `Urls.raw_url` returns nil for.
    # Urls.raw_url returns nil if it doesn't match `https://github.com/[^/]+/[^/]+/blob/`

    # So a path like /foo/bar/raw
    # path extracted: /foo/bar
    # github url: https://github.com/foo/bar
    # raw_url("https://github.com/foo/bar") -> nil (because regex requires /blob/)

    conn =
      build_conn()
      |> Map.put(:path_info, ["foo", "bar", "raw"])
      |> Map.put(:request_path, "/foo/bar/raw")
      |> RawUrlRedirector.call(%{})

    refute conn.halted
  end

  describe "integration" do
    test "redirects when hitting the router with /raw", %{conn: conn} do
      path = "/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd/raw"

      conn = get(conn, path)

      assert redirected_to(conn) ==
               "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd"
    end

    test "does not redirect normal requests", %{conn: conn} do
      # This path should just fail 404 or be handled by the catch all if it exists,
      # but definitely NOT be redirected by our plug.
      # The router has a catch-all `live("/*file", ...)` so it might return html.
      path = "/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd"

      # We expect this to NOT redirect to the raw url.
      # It might raise error if the notebook doesn't exist in DB, but the plug happens BEFORE the liveview.
      # So we can just check it wasn't redirected to the external raw url.

      # However, if it hits the controller/liveview, it might crash if data is missing.
      # But `get(conn, path)` will catch exceptions if valid.

      # actually, let's use a path that definitely doesn't match the plug's criteria but is valid,
      # or just assert `conn.status != 302` (or if it is 302, not to external raw url).

      # Since we don't have DB fixtures here, it will likely crash in the LiveView.
      # But we only care that the Plug PASSED it through.

      assert_error_sent 404, fn ->
        get(conn, path)
      end
    end
  end
end
