defmodule NotesclubWeb.ErrorViewTest do
  use NotesclubWeb.ConnCase, async: true

  test "renders 404 page" do
    response =
      assert_error_sent(:not_found, fn ->
        get(build_conn(), "/non-existent")
      end)

    {404, [_h | _t], html} = response
    assert html =~ "This Livebook doesn't exist"
  end

  test "renders 500 page" do
    response =
      assert_error_sent(500, fn ->
        get(build_conn(), "/dummy/raise_error")
      end)

    {500, [_h | _t], html} = response
    assert html =~ "Oops. There was an error."
  end
end
