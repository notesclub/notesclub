defmodule NotesclubWeb.DummyErrorController do
  @moduledoc """
  Used to test 500 page in dev and test env.
  """

  use NotesclubWeb, :controller

  def raise_error(_conn, _params) do
    raise "An error has occurred"
  end
end
