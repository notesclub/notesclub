defmodule NotesclubWeb.AuthController do
  use NotesclubWeb, :controller
  plug Ueberauth

  alias Notesclub.Accounts

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.get_by_github_id(auth.uid) do
      nil ->
        {:ok, user} = Accounts.create_user(%{
          username: auth.info.nickname,
          github_id: auth.uid,
          name: auth.info.name,
          avatar_url: auth.info.urls.avatar_url
        })

        conn
        |> put_session(:user_id, user.id)
        |> redirect(to: "/")

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
