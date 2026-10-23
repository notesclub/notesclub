defmodule NotesclubWeb.ReturnToController do
  @moduledoc """
  This controller is used to store the path we should redirect back to after
  logging-in / signing-up, etc.
  Required to store the path in LiveView's live_patch/2, push_patch/2, etc.
  """

  use NotesclubWeb, :controller

  # POST "/_return_to", body: path=/posts/42
  def create(conn, %{"path" => path}) when is_binary(path) do
    if valid_local_path?(path) do
      conn
      |> put_session(:return_to, path)
      |> send_resp(:no_content, "")
    else
      send_resp(conn, :unprocessable_entity, "invalid return path")
    end
  end

  def create(conn, _params) do
    send_resp(conn, :unprocessable_entity, "invalid return path")
  end

  defp valid_local_path?(path) when byte_size(path) <= 2_048 do
    valid_path_shape?(path) and valid_path_shape?(URI.decode(path))
  rescue
    ArgumentError -> false
  end

  defp valid_local_path?(_path), do: false

  defp valid_path_shape?(path) do
    String.starts_with?(path, "/") and
      not String.starts_with?(path, "//") and
      not String.contains?(path, "\\") and
      not String.match?(path, ~r/[\x00-\x1F\x7F]/)
  end
end
