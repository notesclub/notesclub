defmodule NotesclubWeb.AuthController do
  use NotesclubWeb, :controller
  plug Ueberauth

  alias Notesclub.Accounts

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.get_by_github_id(auth.uid) do
      nil ->
        user_params = %{
          username: auth.info.nickname,
          github_id: auth.uid,
          name: auth.info.name,
          avatar_url: auth.info.urls.avatar_url
        }

        case Accounts.create_user(user_params) do
          {:ok, user} ->
            conn
            |> put_session(:user_id, user.id)
            |> redirect(to: "/")

          {:error, _changeset} ->
            conn
            |> put_session(:user_id, nil)
            |> put_flash(:error, "There was an issue creating your account.")
            |> redirect(to: "/")
        end

      user ->
        conn
        |> put_session(:user_id, user.id)
        |> redirect(to: "/")
    end
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end
