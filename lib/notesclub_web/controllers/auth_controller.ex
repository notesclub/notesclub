defmodule NotesclubWeb.AuthController do
  use NotesclubWeb, :controller
  plug Ueberauth

  alias Notesclub.Accounts
  alias Notesclub.Workers.XScheduledPostWorker
  alias Notesclub.X

  @x_oauth_state_key :x_oauth_state
  @x_pkce_verifier_key :x_pkce_verifier

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    conn = fetch_session(conn)
    return_to = get_session(conn, :return_to) || "/"

    case Accounts.get_by_github_id(auth.uid) do
      nil ->
        case Accounts.create_user(to_user_params(auth)) do
          {:ok, user} ->
            conn
            |> put_session(:user_id, user.id)
            |> put_flash(:info, "Welcome to Notesclub!")
            |> redirect(to: return_to)

          {:error, _changeset} ->
            conn
            |> put_session(:user_id, nil)
            |> put_flash(:error, "There was an issue creating your account.")
            |> redirect(to: return_to)
        end

      user ->
        Accounts.update_user(user, to_user_params(auth))

        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: return_to)
    end
  end

  def request(conn, %{"provider" => provider}) do
    Ueberauth.Strategy.run_request(conn, provider)
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  def botsignin(conn, _params) do
    state = secure_url_token()
    code_verifier = secure_url_token()
    code_challenge = pkce_code_challenge(code_verifier)

    conn
    |> put_session(@x_oauth_state_key, state)
    |> put_session(@x_pkce_verifier_key, code_verifier)
    |> redirect(external: X.get_authorize_url(state: state, code_challenge: code_challenge))
  end

  def botcallback(conn, %{"code" => auth_code, "state" => state}) do
    with {:ok, code_verifier} <- verify_x_oauth_session(conn, state),
         {:ok, _access_token} <- X.authenticate(auth_code, code_verifier) do
      # Successfully authenticated and stored token.
      # Post once immediately as a test; cron handles scheduled posts.
      XScheduledPostWorker.new(%{}) |> Oban.insert()

      conn
      |> clear_x_oauth_session()
      |> put_flash(
        :info,
        "Successfully authenticated with X. Automated posting is now configured to run every 8 hours."
      )
      |> redirect(to: "/")
    else
      _ ->
        failed_x_auth(conn)
    end
  end

  def botcallback(conn, _params) do
    failed_x_auth(conn)
  end

  defp failed_x_auth(conn) do
    conn
    |> clear_x_oauth_session()
    |> put_flash(:error, "Failed to authenticate with X.")
    |> redirect(to: "/")
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
      twitter_username: auth.extra.raw_info.user["twitter_username"],
      last_login_at: DateTime.utc_now()
    }
  end

  defp verify_x_oauth_session(conn, state) when is_binary(state) do
    expected_state = get_session(conn, @x_oauth_state_key)
    code_verifier = get_session(conn, @x_pkce_verifier_key)

    if is_binary(expected_state) and is_binary(code_verifier) and
         Plug.Crypto.secure_compare(expected_state, state) do
      {:ok, code_verifier}
    else
      {:error, :invalid_oauth_state}
    end
  end

  defp verify_x_oauth_session(_conn, _state), do: {:error, :invalid_oauth_state}

  defp clear_x_oauth_session(conn) do
    conn
    |> delete_session(@x_oauth_state_key)
    |> delete_session(@x_pkce_verifier_key)
  end

  defp secure_url_token do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp pkce_code_challenge(code_verifier) do
    :sha256
    |> :crypto.hash(code_verifier)
    |> Base.url_encode64(padding: false)
  end
end
