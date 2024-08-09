defmodule NotesclubWeb.SitemapController do
  use NotesclubWeb, :controller

  import Notesclub.Notebooks, only: [get_latest_notebook: 0]

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Paths
  alias Notesclub.Packages

  @doc """
  Generates a sitemap for the home, the /top page and packages
  """
  def packages_sitemap(conn, _params) do
    sitemap = sitemap_from_ets_or_generate("packages")

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, sitemap)
  end

  @doc """
  Generates a sitemap for all notebooks that have at least 1 clap
  """
  def clapped_notebooks_sitemap(conn, _params) do
    sitemap = sitemap_from_ets_or_generate("clapped-notebooks")

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, sitemap)
  end

  @doc """
  Regenerates the sitemaps for packages and clapped notebooks
  So we call it in a job every day
  """
  def regenerate_sitemaps do
    table = ensure_ets_table_exists()

    sitemap = generate_sitemap("packages")
    :ets.insert(table, {"packages", sitemap})

    sitemap = generate_sitemap("clapped-notebooks")
    :ets.insert(table, {"clapped-notebooks", sitemap})

    :ok
  end

  defp sitemap_from_ets_or_generate(key) do
    table = ensure_ets_table_exists()

    case :ets.lookup(table, key) do
      [] ->
        sitemap = generate_sitemap(key)
        :ets.insert(table, {key, sitemap})
        sitemap

      sitemap ->
        sitemap
    end
  end

  defp generate_sitemap("packages") do
    date = Calendar.strftime(get_latest_notebook().inserted_at, "%Y-%m-%d")
    package_names = Packages.list_package_names()

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      <url>
        <loc>https://notes.club</loc>
        <lastmod>#{date}</lastmod>
        <changefreq>daily</changefreq>
        <priority>1</priority>
      </url>
      <url>
        <loc>https://notes.club/top</loc>
        <changefreq>monthly</changefreq>
        <priority>0.9</priority>
      </url>
      <url>
        <loc>https://notes.club/random</loc>
        <changefreq>daily</changefreq>
        <priority>0.9</priority>
      </url>
      #{Enum.map(package_names, &package_url/1)}
    </urlset>
    """
  end

  defp generate_sitemap("clapped-notebooks") do
    clapped_notebooks = Notebooks.list_notebooks(claps_gte: 1)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      #{Enum.map(clapped_notebooks, &notebook_url/1)}
    </urlset>
    """
  end

  def ensure_ets_table_exists() do
    case :ets.whereis(:sitemap) do
      :undefined ->
        :ets.new(:sitemap, [:set, :protected])

      existing_table ->
        existing_table
    end
  end

  defp notebook_url(notebook) do
    url = "https://notes.club" <> Paths.url_to_path(notebook.url || notebook.github_html_url)
    last_mod = Calendar.strftime(notebook.updated_at, "%Y-%m-%d")

    """
    <url>
      <loc>#{url}</loc>
      <lastmod>#{last_mod}</lastmod>
      <changefreq>monthly</changefreq>
      <priority>0.8</priority>
    </url>
    """
  end

  defp package_url(name) do
    """
    <url>
      <loc>"https://notes.club/hex/#{name}"</loc>
      <changefreq>monthly</changefreq>
      <priority>0.7</priority>
    </url>
    """
  end
end
