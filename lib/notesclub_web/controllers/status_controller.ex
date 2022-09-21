defmodule NotesclubWeb.StatusController do
  use NotesclubWeb, :controller

  def ok(conn, _params), do: text(conn, "OK")
end
