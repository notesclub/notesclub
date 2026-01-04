defmodule NotesclubWeb.PageController do
  use NotesclubWeb, :controller

  alias Notesclub.Notebooks.Urls

  def terms(conn, _params) do
    render(conn, "terms.html")
  end

  def privacy_policy(conn, _params) do
    render(conn, "privacy_policy.html")
  end
end
