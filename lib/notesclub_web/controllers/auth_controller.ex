defmodule NotesclubWeb.AuthController do
  use NotesclubWeb, :controller
  plug Ueberauth

  alias Notesclub.Accounts
  alias Notesclub.X
  alias Notesclub.Workers.XScheduledPostWorker

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.get_by_github_id(auth.uid) do
      nil ->
        case Accounts.create_user(to_user_params(auth)) do
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
        Accounts.update_user(user, to_user_params(auth))

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

  def botsignin(conn, _params) do
    redirect(conn, external: X.get_authorize_url())
  end

  def botcallback(conn, %{"code" => auth_code}) do
    case X.authenticate(auth_code) do
      {:ok, _access_token} ->
        # Successfully authenticated and stored token
        # Post once immediately as a test, cron will handle scheduled posts

        XScheduledPostWorker.new(%{}) |> Oban.insert()

        conn
        |> put_flash(
          :info,
          "Successfully authenticated with X. Automated posting is now configured to run every 8 hours."
        )
        |> redirect(to: "/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to authenticate with X.")
        |> redirect(to: "/")
    end
  end

  defp to_user_params(auth) do
    %{
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
  end
end
