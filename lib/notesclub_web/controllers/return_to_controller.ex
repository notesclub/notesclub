defmodule NotesclubWeb.ReturnToController do
  @moduledoc """
  This controller is used to store the path we should redirect back to after
  logging-in / signing-up, etc.
  Required to store the path in LiveView's live_patch/2, push_patch/2, etc.
  """

  use NotesclubWeb, :controller

  # POST "/_return_to", body: path=/posts/42
  def create(conn, %{"path" => path}) do
    conn
    |> put_session(:return_to, path)
    |> send_resp(:no_content, "")
  end
end
