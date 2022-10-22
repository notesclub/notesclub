defmodule Notesclub.NotebooksTest do
  use Notesclub.DataCase

  alias Notesclub.Notebooks
  alias Notesclub.SearchesFixtures
  alias Notesclub.AccountsFixtures
  alias Notesclub.Accounts
  alias Notesclub.Repos

  describe "notebooks" do
    alias Notesclub.Notebooks.Notebook

    import Notesclub.NotebooksFixtures

    @invalid_attrs %{
      github_filename: nil,
      github_html_url: nil,
      github_owner_avatar_url: nil,
      github_owner_login: nil,
      github_repo_name: nil,
      search: nil
    }

    test "list_notebooks/0 ascending order" do
      notebook1 = notebook_fixture()
      notebook2 = notebook_fixture()
      assert Notebooks.list_notebooks() == [notebook1, notebook2]
      assert Notebooks.list_notebooks(order: :asc) == [notebook1, notebook2]
    end

    test "list_notebooks/0 descending order" do
      notebook1 = notebook_fixture()
      notebook2 = notebook_fixture()
      assert Notebooks.list_notebooks(order: :desc) == [notebook2, notebook1]
    end

    test "list_notebooks/1 search by github_filename" do
      notebook = notebook_fixture(%{github_filename: "found.livemd"})
      _other_notebook = notebook_fixture(%{github_filename: "not_present.livemd"})

      assert Notebooks.list_notebooks(github_filename: "found") == [notebook]
      # case insensitive
      assert Notebooks.list_notebooks(github_filename: "FOUND") == [notebook]
    end

    # Ensure all filters integrate correctly
    test "list_notebooks/1 search by all filters" do
      notebook1 = notebook_fixture(%{github_filename: "found.livemd"})
      notebook2 = notebook_fixture(%{github_filename: "found.livemd"})
      _other_notebook = notebook_fixture(%{github_filename: "not_present.livemd"})

      assert Notebooks.list_notebooks(github_filename: "found", order: :desc) == [
               notebook2,
               notebook1
             ]

      assert Notebooks.list_notebooks(github_filename: "found", order: :asc) == [
               notebook1,
               notebook2
             ]
    end

    test "list_notebooks_since/1 returns notebooks since n days ago" do
      # We create a notebook and confirm we get it
      notebook1 = notebook_fixture()
      assert Notebooks.list_notebooks_since(2) == [notebook1]

      # We change the time and now we do NOT get it
      {:ok, _} = Notebooks.update_notebook(notebook1, %{inserted_at: DateTools.days_ago(3)})
      assert Notebooks.list_notebooks_since(2) == []

      # We create two more notebooks
      notebook2 = notebook_fixture()
      notebook3 = notebook_fixture()

      # Now we get these two — without notebook1
      assert Notebooks.list_notebooks_since(2) == [notebook3, notebook2]
    end

    test "get_notebook!/1 returns the notebook with given id" do
      notebook = notebook_fixture()
      assert Notebooks.get_notebook!(notebook.id) == notebook
    end

    test "get_notebook!/1 preloads user and repo" do
      original_notebook = notebook_fixture()
      preloaded_notebook = Notebooks.get_notebook!(original_notebook.id, preload: [:user, :repo])
      assert original_notebook.id == preloaded_notebook.id
      assert original_notebook.user_id == preloaded_notebook.user.id
      assert original_notebook.repo_id == preloaded_notebook.repo.id
    end

    test "create_notebook/1 with valid data creates a notebook, a repo and a user" do
      search = SearchesFixtures.search_fixture()

      valid_attrs = %{
        url: "some url",
        content: "whatever",
        github_filename: "some github_filename",
        github_html_url: "some github_html_url",
        github_owner_avatar_url: "some github_owner_avatar_url",
        github_owner_login: "some_github_owner_login",
        github_repo_name: "some_github_repo_name",
        github_repo_full_name: "some_github_owner_login/some_github_repo_name",
        github_repo_fork: true,
        search_id: search.id
      }

      assert {:ok, %Notebook{} = notebook} = Notebooks.create_notebook(valid_attrs)
      assert notebook.url == "some url"
      assert notebook.content == "whatever"
      assert notebook.github_filename == "some github_filename"
      assert notebook.github_html_url == "some github_html_url"
      assert notebook.github_owner_avatar_url == "some github_owner_avatar_url"
      assert notebook.github_owner_login == "some_github_owner_login"
      assert notebook.github_repo_name == "some_github_repo_name"
      assert notebook.search_id == search.id
      assert notebook.repo_id != nil
      assert notebook.repo.user_id != nil

      repo = Repos.get_repo!(notebook.repo_id, preload: :user)
      assert repo.name == "some_github_repo_name"
      assert repo.full_name == "some_github_owner_login/some_github_repo_name"
      assert repo.fork == true
      assert repo.user.username == "some_github_owner_login"
      assert repo.user.avatar_url == "some github_owner_avatar_url"
      assert repo.user_id == notebook.user_id
    end

    test "create_notebook/1 does not create duplicate users" do
      # Arrange

      user = AccountsFixtures.user_fixture()

      notebook_data = %{
        url: "some url",
        content: "whatever",
        github_filename: "some github_filename",
        github_html_url: "some github_html_url",
        github_owner_avatar_url: "some github_owner_avatar_url",
        github_owner_login: user.username,
        github_repo_name: "repo1"
      }

      notebook_data1 = %{
        url: "some url",
        content: "whatever",
        github_filename: "some github_filename",
        github_html_url: "some github_html_url_foo",
        github_owner_avatar_url: "some github_owner_avatar_url",
        github_owner_login: user.username,
        github_repo_name: "repo2"
      }

      {:ok, notebook} = Notebooks.create_notebook(notebook_data1)
      {:ok, new_notebook} = Notebooks.create_notebook(notebook_data)

      assert notebook.user_id == new_notebook.user_id
      repo = Repos.get_repo(notebook.repo_id)
      assert repo.user_id == notebook.user_id
    end

    test "create_notebook/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notebooks.create_notebook(@invalid_attrs)
    end

    test "update_notebook/2 with valid data updates the notebook" do
      notebook = notebook_fixture()

      update_attrs = %{
        github_filename: "some updated github_filename",
        github_html_url: "some updated github_html_url",
        github_owner_avatar_url: "some updated github_owner_avatar_url",
        github_owner_login: "some updated github_owner_login",
        github_repo_name: "some updated github_repo_name"
      }

      assert {:ok, %Notebook{} = notebook} = Notebooks.update_notebook(notebook, update_attrs)
      assert notebook.github_filename == "some updated github_filename"
      assert notebook.github_html_url == "some updated github_html_url"
      assert notebook.github_owner_avatar_url == "some updated github_owner_avatar_url"
      assert notebook.github_owner_login == "some updated github_owner_login"
      assert notebook.github_repo_name == "some updated github_repo_name"
    end

    test "update_notebook/2 with invalid data returns error changeset" do
      notebook = notebook_fixture()
      assert {:error, %Ecto.Changeset{}} = Notebooks.update_notebook(notebook, @invalid_attrs)
      assert notebook == Notebooks.get_notebook!(notebook.id)
    end

    test "delete_notebook/1 deletes the notebook" do
      notebook = notebook_fixture()
      assert {:ok, %Notebook{}} = Notebooks.delete_notebook(notebook)
      assert_raise Ecto.NoResultsError, fn -> Notebooks.get_notebook!(notebook.id) end
    end

    test "change_notebook/1 returns a notebook changeset" do
      notebook = notebook_fixture()
      assert %Ecto.Changeset{} = Notebooks.change_notebook(notebook)
    end

    test "get_by/3 returns a notebook" do
      notebook =
        notebook_fixture(%{
          url: "https://whatever.com"
        })

      assert notebook.id == Notebooks.get_by(url: "https://whatever.com").id
    end
  end
end
