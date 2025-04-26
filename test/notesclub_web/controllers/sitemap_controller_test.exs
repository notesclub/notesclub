defmodule NotesclubWeb.SitemapControllerTest do
  use NotesclubWeb.ConnCase

  import Notesclub.NotebooksFixtures

  test "GET /packages_sitemap.xml", %{conn: conn} do
    notebook_fixture()
    conn = get(conn, ~p"/packages_sitemap.xml")

    assert response(conn, 200) =~ "<loc>https://notes.club</loc>"
  end

  test "GET /clapped_notebooks_sitemap.xml", %{conn: conn} do
    notebook_fixture(%{star_count: 1})
    conn = get(conn, ~p"/clapped_notebooks_sitemap.xml")

    assert response(conn, 200) =~ "<priority>0.8</priority>"
  end
end
