defmodule NotesclubWeb.AuthController do
  use NotesclubWeb, :controller
  plug Ueberauth

  alias Notesclub.Accounts

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.get_by_github_id(auth.uid) do
      nil ->
        user_params = %{
          username: auth.info.nickname,
          github_id: auth.uid,
          name: auth.info.name,
          avatar_url: auth.info.urls.avatar_url,
          bio: auth.extra.raw_info.user["bio"],
          email: auth.info.email,
          location: auth.info.location,
          followers_count: auth.extra.raw_info.user["followers"],
          last_login_at: DateTime.utc_now()
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
        Accounts.update_user(user, %{last_login_at: DateTime.utc_now()})

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
