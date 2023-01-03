defmodule Notesclub.AccountsTest do
  use Notesclub.DataCase

  alias Notesclub.Accounts

  describe "users" do
    alias Notesclub.Accounts.User

    import Notesclub.AccountsFixtures

    @invalid_attrs %{username: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{username: "some name"}

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.username == "some name"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "create_user/1 will create a user without needing a sync" do
      user_no_sync = %{
        username: "test_login_name",
        name: "test_real_name",
        twitter_username: "test_twitter_name",
        avatar_url: "avatar"
      }

      assert {:ok, %User{} = user} = Accounts.create_user(user_no_sync)
      assert user.username == user_no_sync.username
    end

    test "create_user/1 will create and enqueue a update worker" do
      user_sync = %{username: "test_login_name", avatar_url: "avatar"}
      assert {:ok, %User{} = user} = Accounts.create_user(user_sync)
      assert user.username == user_sync.username
      assert_enqueued(worker: Notesclub.Workers.UserSyncWorker, args: %{user_id: user.id})
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{username: "some updated name"}

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.username == "some updated name"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
