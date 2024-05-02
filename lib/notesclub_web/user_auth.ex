defmodule NotesclubWeb.UserAuth do
  import Plug.Conn

  alias Notesclub.Accounts

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id == nil do
      assign(conn, :current_user, nil)
    else
      assign(conn, :current_user, Accounts.get_user(user_id))
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_id = session["user_id"] do
        Accounts.get_user(user_id)
      end
    end)
  end
end
