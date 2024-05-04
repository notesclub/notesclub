defmodule NotesclubWeb.UserAuth do
  @moduledoc """
  A plug for retrieving current user data.
  """

  import Plug.Conn

  alias Notesclub.Accounts

  @doc """
  Handles mounting and retrieving the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_id, or nil if
      there's no user_id or no matching user.
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  @doc """
  Retrieves current user information and assigns it to the connection.
  """
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
