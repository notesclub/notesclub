defmodule Notesclub.NotebooksTest do
  use Notesclub.DataCase

  alias Notesclub.Notebooks

  describe "notebooks" do
    alias Notesclub.Notebooks.Notebook

    import Notesclub.NotebooksFixtures

    @invalid_attrs %{github_filename: nil, github_html_url: nil, github_owner_avatar_url: nil, github_owner_login: nil, github_repo_name: nil, github_api_response: nil}
    @valid_github_api_response %{
      "name" => "structs.livemd",
      "html_url" => "https://github.com/charlieroth/elixir-notebooks/blob/68716ab303da9b98e21be9c04a3c86770ab7c819/structs.livemd",
      "repository" => %{
        "name" => "elixir-notebooks",
        "private" => false,
        "fork" => false,
        "owner" => %{
          "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4",
          "login" => "charlieroth",
        },
      },
    }

    test "list_notebooks/0 returns all notebooks" do
      notebook = notebook_fixture()
      assert Notebooks.list_notebooks() == [notebook]
    end

    test "get_notebook!/1 returns the notebook with given id" do
      notebook = notebook_fixture()
      assert Notebooks.get_notebook!(notebook.id) == notebook
    end

    test "create_notebook/1 with valid data creates a notebook" do
      valid_attrs = %{github_filename: "some github_filename", github_html_url: "some github_html_url", github_owner_avatar_url: "some github_owner_avatar_url", github_owner_login: "some github_owner_login", github_repo_name: "some github_repo_name", github_api_response: @valid_github_api_response}

      assert {:ok, %Notebook{} = notebook} = Notebooks.create_notebook(valid_attrs)
      assert notebook.github_filename == "some github_filename"
      assert notebook.github_html_url == "some github_html_url"
      assert notebook.github_owner_avatar_url == "some github_owner_avatar_url"
      assert notebook.github_owner_login == "some github_owner_login"
      assert notebook.github_repo_name == "some github_repo_name"
    end

    test "create_notebook/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notebooks.create_notebook(@invalid_attrs)
    end

    test "update_notebook/2 with valid data updates the notebook" do
      notebook = notebook_fixture()
      update_attrs = %{github_filename: "some updated github_filename", github_html_url: "some updated github_html_url", github_owner_avatar_url: "some updated github_owner_avatar_url", github_owner_login: "some updated github_owner_login", github_repo_name: "some updated github_repo_name", github_api_response: @valid_github_api_response}

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
  end
end
