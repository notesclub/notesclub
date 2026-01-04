defmodule NotesclubWeb.Plugs.RawUrlRedirector do
  @moduledoc """
  Intercepts requests ending in `/raw` and redirects to the raw GitHub URL.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias Notesclub.Notebooks.Paths
  alias Notesclub.Notebooks.Urls

  def init(opts), do: opts

  def call(conn, _opts) do
    if List.last(conn.path_info) == "raw" do
      path =
        conn.path_info
        |> List.delete_at(-1)
        |> Enum.join("/")

      path = "/" <> path

      with github_url when not is_nil(github_url) <- Paths.path_to_url(path),
           raw_url when not is_nil(raw_url) <- Urls.raw_url(github_url) do
        conn
        |> redirect(external: raw_url)
        |> halt()
      else
        _ ->
          conn
      end
    else
      conn
    end
  end
end
