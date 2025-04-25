defmodule NotesclubWeb.Plugs.AssetInterceptor do
  @moduledoc """
  Intercepts requests for specific asset file extensions and sends a 200 OK response,
  preventing them from hitting downstream routes like LiveViews.

  They come from the `live("/*file", NotebookLive.Show, :show)` route
   when the user is viewing a notebook and, for example, <img> tags are rendered.
  """
  import Plug.Conn

  # Regex to match common asset file extensions at the end of a path.
  @asset_pattern ~r/\.(png|jpg|jpeg|gif|svg|pdf|webp|heic)$/i

  def init(opts), do: opts

  def call(conn, _opts) do
    if String.match?(conn.request_path, @asset_pattern) do
      conn
      |> send_resp(200, "OK")
      |> halt()
    else
      # Not an asset path, continue the pipeline
      conn
    end
  end
end
