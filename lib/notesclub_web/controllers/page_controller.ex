defmodule NotesclubWeb.PageController do
  use NotesclubWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
