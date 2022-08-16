defmodule NotesclubWeb.PageController do
  use NotesclubWeb, :controller

  alias Notesclub.Notebooks

  def index(conn, _params) do
    notebooks = Notebooks.list_notebooks()
    render(conn, "index.html", notebooks: notebooks)
  end
end
