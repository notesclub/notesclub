defmodule NotesclubWeb.AuthControllerTest do
  use NotesclubWeb.ConnCase

  alias Notesclub.Accounts
  alias Notesclub.Accounts.User
  alias Notesclub.Workers.XScheduledPostWorker
  alias Notesclub.X
  alias NotesclubWeb.AuthController

  import Mock

  test "callback/2 persists an error value in flash when fails", %{conn: conn} do
    auth = %Ueberauth.Failure{}

    conn =
      conn
      |> bypass_through(NotesclubWeb.Router, [:browser])
      |> get("/auth/github/callback")
      |> assign(:ueberauth_failure, auth)
      |> AuthController.callback(%{})

    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Failed to authenticate."
  end

  test "callback/2 creates a new user and assigns their ID to the session when one does not exist",
       %{conn: conn} do
    auth = auth_fixture()

    assert [] = Accounts.list_users()

    conn =
      conn
      |> bypass_through(NotesclubWeb.Router, [:browser])
      |> get("/auth/github/callback")
      |> assign(:ueberauth_auth, auth)
      |> AuthController.callback(%{})

    %{"user_id" => id} = get_session(conn)

    assert %User{id: ^id} = Accounts.get_user(id)
    assert [%User{}] = Accounts.list_users()
  end

  test "callback/2 gets the user and assigns their ID to the session when user already exists", %{
    conn: conn
  } do
    params = %{
      username: "John The Doe",
      github_id: 123_123,
      name: "John Doe",
      twitter_username: "someone",
      avatar_url: "https://example.com/image.jpg"
    }

    Accounts.create_user(params)

    auth = auth_fixture()

    conn =
      conn
      |> bypass_through(NotesclubWeb.Router, [:browser])
      |> get("/auth/github/callback")
      |> assign(:ueberauth_auth, auth)
      |> AuthController.callback(%{})

    %{"user_id" => id} = get_session(conn)

    assert %User{id: ^id} = Accounts.get_user(id)
    assert [%User{}] = Accounts.list_users()
  end

  test "botsignin/2 stores X OAuth state and PKCE verifier in session", %{conn: conn} do
    conn =
      conn
      |> bypass_through(NotesclubWeb.Router, [:browser])
      |> get("/x/signin")
      |> AuthController.botsignin(%{})

    %{"x_oauth_state" => state, "x_pkce_verifier" => code_verifier} = get_session(conn)

    query =
      conn
      |> redirected_to()
      |> URI.parse()
      |> Map.fetch!(:query)
      |> URI.decode_query()

    expected_code_challenge =
      :sha256
      |> :crypto.hash(code_verifier)
      |> Base.url_encode64(padding: false)

    assert query["state"] == state
    assert query["code_challenge"] == expected_code_challenge
    assert query["code_challenge_method"] == "S256"
    refute query["code_challenge"] == "challenge"
  end

  test "botcallback/2 rejects missing or mismatched X OAuth state", %{conn: conn} do
    conn = conn_with_x_oauth_session(conn, "expected-state", "code-verifier")

    with_mock X,
      authenticate: fn _code, _verifier -> flunk("X.authenticate/2 should not be called") end do
      conn = AuthController.botcallback(conn, %{"code" => "auth-code", "state" => "bad-state"})

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Failed to authenticate with X."
      assert get_session(conn, :x_oauth_state) == nil
      assert get_session(conn, :x_pkce_verifier) == nil
      refute_enqueued(worker: XScheduledPostWorker)
    end
  end

  test "botcallback/2 exchanges X OAuth code with the stored PKCE verifier", %{conn: conn} do
    conn = conn_with_x_oauth_session(conn, "expected-state", "code-verifier")

    with_mock X, authenticate: fn "auth-code", "code-verifier" -> {:ok, "access-token"} end do
      conn =
        AuthController.botcallback(conn, %{"code" => "auth-code", "state" => "expected-state"})

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Successfully authenticated with X"

      assert get_session(conn, :x_oauth_state) == nil
      assert get_session(conn, :x_pkce_verifier) == nil
      assert_enqueued(worker: XScheduledPostWorker)
      assert called(X.authenticate("auth-code", "code-verifier"))
    end
  end

  defp auth_fixture do
    %Ueberauth.Auth{
      uid: 123_123,
      provider: :github,
      info: %{
        nickname: "John The Doe",
        github_id: 123_123,
        username: "JohnDoe",
        name: "John Doe",
        email: "johndoe@example.com",
        location: "Brazil",
        urls: %{
          avatar_url: "https://example.com/image.jpg"
        }
      },
      extra: %{
        raw_info: %{
          user: %{
            bio: "elixir developer",
            twitter_username: "someone",
            followers: 10
          }
        }
      }
    }
  end

  defp conn_with_x_oauth_session(conn, state, code_verifier) do
    conn
    |> bypass_through(NotesclubWeb.Router, [:browser])
    |> get("/x/callback")
    |> put_session(:x_oauth_state, state)
    |> put_session(:x_pkce_verifier, code_verifier)
  end
end
