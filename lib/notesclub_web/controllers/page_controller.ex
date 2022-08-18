defmodule NotesclubWeb.PageController do
  use NotesclubWeb, :controller

  @notebooks_in_home_count 7
  def notebooks_in_home_count, do: @notebooks_in_home_count

  alias Notesclub.Notebooks

  def index(conn, _params) do
    notebooks = Notebooks.list_random_notebooks(%{limit: @notebooks_in_home_count})
    notebooks_count = Notebooks.count()
    render(conn, "index.html", notebooks: notebooks, notebooks_count: notebooks_count, button: :more, filter: nil)
  end

  def all(conn, _params) do
    notebooks = Notebooks.list_notebooks()
    notebooks_count = Notebooks.count()
    render(conn, "index.html", notebooks: notebooks, notebooks_count: notebooks_count, button: :less, filter: nil)
  end

  def author(conn, %{"author" => author}) do
    notebooks = Notebooks.list_author_notebooks_desc(author)
    notebooks_count = Notebooks.count()
    render(conn, "index.html", notebooks: notebooks, notebooks_count: notebooks_count, button: :more, filter: author)
  end

  def repo(conn, %{"repo" => repo, "author" => author}) do
    notebooks = Notebooks.list_repo_author_notebooks_desc(repo, author)
    notebooks_count = Notebooks.count()
    render(conn, "index.html", notebooks: notebooks, notebooks_count: notebooks_count, button: :more, filter: "#{author}/#{repo}")
  end
end
