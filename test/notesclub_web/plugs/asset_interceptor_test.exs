defmodule NotesclubWeb.Plugs.AssetInterceptorTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias NotesclubWeb.Plugs.AssetInterceptor

  test "does not intercept asset-like paths under protected routes" do
    for path <- ["/oban/anything.png", "/x/signin.png"] do
      conn = AssetInterceptor.call(conn(:get, path), [])
      refute conn.halted
      assert conn.status == nil
    end
  end

  test "continues intercepting relative notebook assets" do
    conn = AssetInterceptor.call(conn(:get, "/author/repo/image.png"), [])
    assert conn.halted
    assert conn.status == 200
    assert conn.resp_body == "OK"
  end
end
