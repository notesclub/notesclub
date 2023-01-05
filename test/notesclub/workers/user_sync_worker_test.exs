defmodule UserSyncWorkerTest do
  use Notesclub.DataCase

  import Mock

  alias Notesclub.{Accounts, AccountsFixtures, GithubAPI}
  alias Notesclub.Workers.UserSyncWorker
  alias Notesclub.GithubAPI

  @github_user_response %Req.Response{
    status: 200,
    body: %{
      "name" => "test_name",
      "twitter_username" => "test_twitter_username"
    }
  }

  @github_no_user_response %Req.Response{
    status: 404,
    body: %{
      "message" => "Not Found"
    }
  }

  describe "perform/1" do
    test "should look up a users github info and update the user" do
      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _options -> @github_user_response end]},
        {GithubAPI, [:passthrough], [check_github_api_key: fn -> false end]}
      ]) do
        user = AccountsFixtures.user_fixture()

        # Run worker:
        assert :ok = perform_job(UserSyncWorker, %{user_id: user.id})

        # It should have updated user:
        user = Accounts.get_user!(user.id)
        assert user.name == "test_name"
        assert user.twitter_username == "test_twitter_username"
      end
    end

    test "should return an error if the user isnt found" do
      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _options -> @github_no_user_response end]}
      ]) do
        user = AccountsFixtures.user_fixture()

        # Run worker:
        assert {:error, _error} = perform_job(UserSyncWorker, %{user_id: user.id})

        # It should not have updated user:
        user = Accounts.get_user!(user.id)
        assert user.name == nil
        assert user.twitter_username == nil
      end
    end
  end
end
