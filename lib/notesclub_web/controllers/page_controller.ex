defmodule NotesclubWeb.PageController do
  use NotesclubWeb, :controller

  @notebooks_in_home_count 7
  def notebooks_in_home_count, do: @notebooks_in_home_count

  alias Notesclub.Notebooks

  def index(conn, _params) do
    notebooks = Notebooks.list_random_notebooks(%{limit: @notebooks_in_home_count})
    notebooks_count = Notebooks.count()
    render(conn, "index.html", notebooks: notebooks, notebooks_count: notebooks_count, all: false)
  end

  def all(conn, _params) do
    notebooks = Notebooks.list_notebooks_desc()
    notebooks_count = Notebooks.count()
    render(conn, "index.html", notebooks: notebooks, notebooks_count: notebooks_count, all: true)
  end
end
