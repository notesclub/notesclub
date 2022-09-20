defmodule NotesclubWeb.StatusController do
  use NotesclubWeb, :controller

  def status(conn, _params), do: text conn, "OK"
end
