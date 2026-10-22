defmodule NotesclubWeb.SitemapControllerTest do
  use NotesclubWeb.ConnCase

  import Notesclub.NotebooksFixtures
  import Notesclub.PackagesFixtures

  alias Notesclub.NotebooksPackages
  alias Notesclub.Repo

  test "GET /packages_sitemap.xml", %{conn: conn} do
    notebook_fixture()
    conn = get(conn, ~p"/packages_sitemap.xml")

    assert response(conn, 200) =~ "<loc>https://notes.club</loc>"
  end

  test "sitemaps escape dynamic XML and prevent content sniffing", %{conn: conn} do
    notebook =
      notebook_fixture(%{url: "https://github.com/owner/repo/blob/main/book.livemd?a=1&b=2"})

    package = package_fixture(%{name: "bad</loc><script>alert(1)</script><loc>&name"})
    :ok = NotebooksPackages.link!(Repo.preload(notebook, :packages), [package])

    package_conn = get(conn, ~p"/packages_sitemap.xml")
    package_xml = response(package_conn, 200)

    assert package_xml =~
             "bad&lt;/loc&gt;&lt;script&gt;alert(1)&lt;/script&gt;&lt;loc&gt;&amp;name"

    refute package_xml =~ "<script>"
    assert get_resp_header(package_conn, "content-type") == ["text/xml; charset=utf-8"]
    assert get_resp_header(package_conn, "x-content-type-options") == ["nosniff"]

    notebook_conn = get(build_conn(), ~p"/clapped_notebooks_sitemap.xml")
    notebook_xml = response(notebook_conn, 200)
    assert notebook_xml =~ "?a=1&amp;b=2</loc>"
    assert get_resp_header(notebook_conn, "x-content-type-options") == ["nosniff"]
  end

  test "GET /clapped_notebooks_sitemap.xml", %{conn: conn} do
    notebook_fixture(%{star_count: 1})
    conn = get(conn, ~p"/clapped_notebooks_sitemap.xml")

    assert response(conn, 200) =~ "<priority>0.8</priority>"
  end
end
