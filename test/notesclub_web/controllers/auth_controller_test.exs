defmodule NotesclubWeb.AuthControllerTest do
  use NotesclubWeb.ConnCase

  alias Notesclub.Accounts
  alias Notesclub.Accounts.User
  alias NotesclubWeb.AuthController

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
end
