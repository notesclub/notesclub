defmodule Notesclub.ReposTest do
  use Notesclub.DataCase

  alias Notesclub.Repos

  describe "repos" do
    alias Notesclub.Repos.Repo

    import Notesclub.ReposFixtures

    @valid_attrs %{name: "myrepo", full_name: "myuser/myrepo"}
    @invalid_attrs %{name: nil}

    test "list_repos/0 returns all repos" do
      repo = repo_fixture()
      assert Repos.list_repos() == [repo]
    end

    test "get_repo!/1 returns the repo with given id" do
      repo = repo_fixture()
      assert Repos.get_repo!(repo.id) == repo
    end

    test "create_repo/1 with valid data creates a repo & enqueues worker" do
      assert {:ok, %Repo{} = repo} = Repos.create_repo(@valid_attrs)
      assert repo.name == @valid_attrs.name
      assert_enqueued [worker: Notesclub.Workers.RepoDefaultBranchWorker, args: %{repo_id: repo.id}]
    end

    test "create_repo/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Repos.create_repo(@invalid_attrs)
    end

    test "update_repo/2 with valid data updates the repo" do
      repo = repo_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Repo{} = repo} = Repos.update_repo(repo, update_attrs)
      assert repo.name == "some updated name"
    end

    test "update_repo/2 with invalid data returns error changeset" do
      repo = repo_fixture()
      assert {:error, %Ecto.Changeset{}} = Repos.update_repo(repo, @invalid_attrs)
      assert repo == Repos.get_repo!(repo.id)
    end

    test "delete_repo/1 deletes the repo" do
      repo = repo_fixture()
      assert {:ok, %Repo{}} = Repos.delete_repo(repo)
      assert_raise Ecto.NoResultsError, fn -> Repos.get_repo!(repo.id) end
    end

    test "change_repo/1 returns a repo changeset" do
      repo = repo_fixture()
      assert %Ecto.Changeset{} = Repos.change_repo(repo)
    end
  end
end
