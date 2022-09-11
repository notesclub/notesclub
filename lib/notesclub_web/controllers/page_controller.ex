defmodule NotesclubWeb.PageController do
  use NotesclubWeb, :controller

  @notebooks_in_home_count 7
  def notebooks_in_home_count, do: @notebooks_in_home_count

  alias Notesclub.Notebooks

  def index(conn, _params) do
    notebooks = Notebooks.list_random_notebooks(%{limit: @notebooks_in_home_count})
    notebooks_count = Notebooks.count()

    render(conn, "index.html",
      notebooks: notebooks,
      notebooks_count: notebooks_count,
      page: :random,
      filter: nil
    )
  end

  def all(conn, %{"search" => search}) do
    notebooks = Notebooks.list_notebooks(github_filename: search)
    notebooks_count = Notebooks.count()

    render(conn, "index.html",
      notebooks: notebooks,
      notebooks_count: notebooks_count,
      page: :all,
      filter: nil
    )
  end

  def all(conn, _params) do
    notebooks = Notebooks.list_notebooks(order: :desc)
    notebooks_count = Notebooks.count()

    render(conn, "index.html",
      notebooks: notebooks,
      notebooks_count: notebooks_count,
      page: :all,
      filter: nil
    )
  end

  def last_week(conn, _params) do
    notebooks = Notebooks.list_notebooks_since(7)
    notebooks_count = Notebooks.count()

    render(conn, "index.html",
      notebooks: notebooks,
      notebooks_count: notebooks_count,
      page: :last_week,
      filter: nil
    )
  end

  def author(conn, %{"author" => author}) do
    notebooks = Notebooks.list_author_notebooks_desc(author)
    notebooks_count = Notebooks.count()

    render(conn, "index.html",
      notebooks: notebooks,
      notebooks_count: notebooks_count,
      page: :author,
      filter: author
    )
  end

  def repo(conn, %{"repo" => repo, "author" => author}) do
    notebooks = Notebooks.list_repo_author_notebooks_desc(repo, author)
    notebooks_count = Notebooks.count()

    render(conn, "index.html",
      notebooks: notebooks,
      notebooks_count: notebooks_count,
      page: :repo,
      filter: "#{author}/#{repo}"
    )
  end
end
