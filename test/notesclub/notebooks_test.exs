defmodule Notesclub.NotebooksTest do
  use Notesclub.DataCase

  alias Notesclub.AccountsFixtures
  alias Notesclub.Notebooks
  alias Notesclub.Repos
  alias Notesclub.ReposFixtures
  alias Notesclub.Stars
  import Notesclub.NotebooksFixtures
  import Notesclub.ReposFixtures
  import Notesclub.AccountsFixtures

  describe "notebooks" do
    alias Notesclub.Notebooks.Notebook

    @invalid_attrs %{
      github_filename: nil,
      github_html_url: nil,
      github_owner_avatar_url: nil,
      github_owner_login: nil,
      github_repo_name: nil,
      search: nil
    }

    test "get_latest_notebook/0" do
      _notebook1 = notebook_fixture(inserted_at: ~N[2022-12-31 20:00:00])
      notebook2 = notebook_fixture(inserted_at: ~N[2023-01-01 20:00:00])
      assert Notebooks.get_latest_notebook() == notebook2
    end

    test "list_notebooks/0 ascending order" do
      notebook1 = notebook_fixture(content: nil)
      notebook2 = notebook_fixture(content: nil)
      assert Notebooks.list_notebooks() == [notebook1, notebook2]
      assert Notebooks.list_notebooks(order: :asc) == [notebook1, notebook2]
    end

    test "list_notebooks/0 descending order" do
      notebook1 = notebook_fixture(content: nil)
      notebook2 = notebook_fixture(content: nil)
      assert Notebooks.list_notebooks(order: :desc) == [notebook2, notebook1]
    end

    test "list_notebooks/1 selects content field" do
      notebook = notebook_fixture()
      assert Notebooks.list_notebooks(select_content: true) == [notebook]
    end

    test "list_notebooks/1 search by github_filename" do
      notebook = notebook_fixture(github_filename: "found.livemd", content: nil)
      _other_notebook = notebook_fixture(github_filename: "not_present.livemd")

      assert Notebooks.list_notebooks(github_filename: "found") == [notebook]
      # case insensitive
      assert Notebooks.list_notebooks(github_filename: "FOUND") == [notebook]
    end

    test "list_notebooks/1 search by github_owner_login" do
      notebook = notebook_fixture(github_owner_login: "one", content: nil)
      _other_notebook = notebook_fixture(github_owner_login: "two")

      assert Notebooks.list_notebooks(github_owner_login: "one") == [notebook]
    end

    test "list_notebooks/1 search by github_repo_name" do
      notebook = notebook_fixture(github_repo_name: "one", content: nil)
      _other_notebook = notebook_fixture(github_repo_name: "two")

      assert Notebooks.list_notebooks(github_repo_name: "one") == [notebook]
    end

    # Ensure all filters integrate correctly
    test "list_notebooks/1 search by all filters" do
      notebook1 = notebook_fixture(github_filename: "found.livemd", content: nil)
      notebook2 = notebook_fixture(github_filename: "found.livemd", content: nil)
      _other_notebook = notebook_fixture(github_filename: "not_present.livemd")

      assert Notebooks.list_notebooks(github_filename: "found", order: :desc) == [
               notebook2,
               notebook1
             ]

      assert Notebooks.list_notebooks(github_filename: "found", order: :asc) == [
               notebook1,
               notebook2
             ]
    end

    test "list_notebooks/1 search by searchable" do
      user = user_fixture(name: "Jose Valim")
      notebook_fixture(github_owner_login: "whatever", user_id: user.id)

      notebook_fixture(github_owner_login: "josevalim")
      notebook_fixture()
      notebook_fixture(github_repo_name: "valim-ideas", github_owner_login: "someone")

      assert Notebooks.list_notebooks(searchable: "valim", order: :asc)
             |> Enum.map(& &1.github_owner_login) == ["whatever", "josevalim", "someone"]
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

    test "create_notebook/1 with repo_id saves user_id=repo.user_id" do
      repo = ReposFixtures.repo_fixture()

      valid_attrs = %{
        repo_id: repo.id,
        url: "some url",
        content: "whatever",
        github_filename: "some github_filename",
        github_html_url: "some github_html_url",
        github_owner_avatar_url: "some github_owner_avatar_url",
        github_owner_login: "some_github_owner_login",
        github_repo_name: "some_github_repo_name",
        github_repo_full_name: "some_github_owner_login/some_github_repo_name",
        github_repo_fork: true
      }

      assert {:ok, %Notebook{} = notebook} = Notebooks.create_notebook(valid_attrs)
      assert notebook.repo_id == repo.id
      assert notebook.user_id == repo.user_id
    end

    test "create_notebook/1 with valid data creates a notebook, a repo and a user" do
      valid_attrs = %{
        url: "some url",
        content: "whatever",
        github_filename: "some github_filename",
        github_html_url: "some github_html_url",
        github_owner_avatar_url: "some github_owner_avatar_url",
        github_owner_login: "some_github_owner_login",
        github_repo_name: "some_github_repo_name",
        github_repo_full_name: "some_github_owner_login/some_github_repo_name",
        github_repo_fork: true
      }

      assert {:ok, %Notebook{} = notebook} = Notebooks.create_notebook(valid_attrs)
      assert notebook.url == "some url"
      assert notebook.content == "whatever"
      assert notebook.github_filename == "some github_filename"
      assert notebook.github_html_url == "some github_html_url"
      assert notebook.github_owner_avatar_url == "some github_owner_avatar_url"
      assert notebook.github_owner_login == "some_github_owner_login"
      assert notebook.github_repo_name == "some_github_repo_name"
      assert notebook.repo_id != nil
      assert notebook.user_id != nil
      assert notebook.user_id == notebook.repo.user_id

      repo = Repos.get_repo!(notebook.repo_id, preload: :user)
      assert repo.name == "some_github_repo_name"
      assert repo.full_name == "some_github_owner_login/some_github_repo_name"
      assert repo.fork == true
      assert repo.user_id != nil
      assert repo.user.username == "some_github_owner_login"
      assert repo.user.avatar_url == "some github_owner_avatar_url"
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

    defp github_html_url(repo_full_name, sha) do
      "https://github.com/#{repo_full_name}/blob/#{sha}/whatever.livemd"
    end

    test "save_notebook/1 with repo updates notebook because of url" do
      user = user_fixture(username: "oneuser")

      repo = repo_fixture(name: "onerepo", default_branch: "main", full_name: "oneuser/onerepo")

      commit1 = "34d6etc"

      notebook =
        notebook_fixture(
          github_html_url: github_html_url(repo.full_name, commit1),
          url: github_html_url(repo.full_name, repo.default_branch),
          repo_id: repo.id,
          github_owner_login: user.username,
          github_repo_name: repo.name,
          github_repo_full_name: repo.full_name,
          github_filename: "whatever.livemd",
          github_owner_avatar_url: "https://avatars.githubusercontent.com/u/13981427?v=4",
          github_repo_fork: false
        )

      commit2 = "8321etc"

      notebook_data = %{
        github_html_url: github_html_url(repo.full_name, commit2),
        github_owner_login: user.username,
        github_repo_name: repo.name,
        github_repo_full_name: repo.full_name,
        github_filename: "whatever.livemd",
        github_owner_avatar_url: "https://avatars.githubusercontent.com/u/13981427?v=4",
        github_repo_fork: false
      }

      {:ok, updated_notebook} = Notebooks.save_notebook(notebook_data)
      assert updated_notebook.id == notebook.id
    end

    test "save_notebook/1 without repo updates notebook because of github_html_url" do
      html_url = github_html_url("qwqw/ewqeq", "93823etc")
      notebook = notebook_fixture(github_html_url: html_url)

      notebook_data = %{
        github_html_url: html_url,
        github_owner_login: "non-existent-user-yet",
        github_repo_name: "non-existent-repo-yet",
        github_repo_full_name: "non-existent-user-yet/non-existent-repo-yet",
        github_filename: "whatever.livemd",
        github_owner_avatar_url: "https://avatars.githubusercontent.com/u/13981427?v=4",
        github_repo_fork: false
      }

      {:ok, updated_notebook} = Notebooks.save_notebook(notebook_data)
      assert updated_notebook.id == notebook.id
    end

    test "save_notebook/1 creates notebook" do
      html_url = github_html_url("josevalim/one_repo", "2323etc")

      notebook_data = %{
        github_html_url: html_url,
        github_owner_login: "josevalim",
        github_repo_name: "one_repo",
        github_repo_full_name: "josevalim/one_repo",
        github_filename: "whatever.livemd",
        github_owner_avatar_url: "https://avatars.githubusercontent.com/u/13981427?v=4",
        github_repo_fork: false
      }

      assert Notebooks.list_notebooks() == []
      {:ok, notebook} = Notebooks.save_notebook(notebook_data)
      assert Notebooks.list_notebooks() |> Enum.map(& &1.id) == [notebook.id]
      assert notebook.github_html_url == html_url
      assert notebook.user_id
      assert notebook.repo_id
      # ... (tested in create_notebook/1)
    end

    test "delete_notebook/1 deletes the notebook" do
      notebook = notebook_fixture()
      assert {:ok, %Notebook{}} = Notebooks.delete_notebook(notebook)
      assert_raise Ecto.NoResultsError, fn -> Notebooks.get_notebook!(notebook.id) end
    end

    test "delete_notebooks/1 deletes notebooks except the given ids" do
      _n1 = notebook_fixture(github_owner_login: "one")
      n2 = notebook_fixture(github_owner_login: "one", content: nil)
      _n3 = notebook_fixture(github_owner_login: "one")
      n4 = notebook_fixture(content: nil)

      assert Notebooks.delete_notebooks(%{username: "one", except_ids: [n2.id]}) ==
               {:ok, {2, nil}}

      assert Notebooks.list_notebooks(order: :asc) == [n2, n4]
    end

    test "change_notebook/1 returns a notebook changeset" do
      notebook = notebook_fixture()
      assert %Ecto.Changeset{} = Notebooks.change_notebook(notebook)
    end

    test "get_by/1 returns a notebook" do
      notebook =
        notebook_fixture(
          url: "different",
          github_html_url: "different",
          github_owner_login: "different",
          github_repo_name: "different"
        )

      assert notebook == Notebooks.get_by(url: notebook.url)
      assert notebook == Notebooks.get_by(github_html_url: notebook.github_html_url)
      assert notebook == Notebooks.get_by(github_owner_login: notebook.github_owner_login)
      assert notebook == Notebooks.get_by(github_repo_name: notebook.github_repo_name)
    end

    test "extract_title/1 returns the title" do
      title = "That's a title"

      content = """
      # #{title}
      ## That's a subtitle
      That's content
      """

      assert Notebooks.extract_title(content) == title
    end

    test "extract_title/1 with <!-- returns the title" do
      title = "2023 Advent of Code Day 14"

      content = """
      <!-- livebook:{"persist_outputs":true} -->

      # #{title}

      ```elixir
      Mix.install([
        {:kino, "~> 0.7.0"},
        {:explorer, "~> 0.4.0"}
      ])
      ```

      # kk
      lll
      """

      assert Notebooks.extract_title(content) == title
    end

    test "content_fragment/2 extracts fragment" do
      content = """
      # Advent of code 2021 🎄🤶🏽

      Task.async(fn ->
        ...
      end)
      """

      notebook = notebook_fixture(content: content)
      assert Notebooks.content_fragment(notebook, "advent") == "...# advent of code 2021 🎄🤶🏽..."
      assert Notebooks.content_fragment(notebook, "task.async") == "...task.async(fn ->..."
    end

    test "content_fragment/2 works when content excludes search" do
      notebook = notebook_fixture(content: "whatever")
      assert Notebooks.content_fragment(notebook, "day23") == nil
    end

    test "list_notebooks/1 filters by stars_gte" do
      # Create notebooks and users
      notebook1 = notebook_fixture()
      notebook2 = notebook_fixture()
      user1 = user_fixture()
      user2 = user_fixture()

      # Star notebook2 twice
      {:ok, _} = Stars.toggle_star(notebook2, user1)
      {:ok, _} = Stars.toggle_star(notebook2, user2)

      # Star notebook1 once
      {:ok, _} = Stars.toggle_star(notebook1, user1)

      # Filter notebooks with at least 2 stars
      notebooks = Notebooks.list_notebooks(stars_gte: 2)
      assert Enum.map(notebooks, & &1.id) == [notebook2.id]

      # Filter notebooks with at least 1 star
      notebooks = Notebooks.list_notebooks(stars_gte: 1)

      assert Enum.map(notebooks, & &1.id) |> Enum.sort() ==
               [notebook1.id, notebook2.id] |> Enum.sort()
    end
  end

  describe "get_most_starred_recent_notebook/0" do
    import Notesclub.PublishLogsFixtures

    setup do
      user = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      {:ok, %{user: user, user2: user2, user3: user3}}
    end

    test "returns the most starred notebook created in the last 14 days", %{
      user: user,
      user2: user2,
      user3: user3
    } do
      # Recent, 2 stars, long content, not published
      recent_starred =
        notebook_fixture(%{
          inserted_at: DateTools.days_ago(7),
          content: String.duplicate("a", 200),
          user_id: user.id
        })

      {:ok, _} = Stars.toggle_star(recent_starred, user2)
      {:ok, _} = Stars.toggle_star(recent_starred, user3)

      # Recent, 1 star, long content, not published
      recent_less_starred =
        notebook_fixture(%{
          inserted_at: DateTools.days_ago(5),
          content: String.duplicate("b", 200),
          user_id: user.id
        })

      {:ok, _} = Stars.toggle_star(recent_less_starred, user2)

      # Older, 3 stars, long content, not published (should be ignored)
      old_starred =
        notebook_fixture(%{
          inserted_at: DateTools.days_ago(15),
          content: String.duplicate("c", 200),
          user_id: user.id
        })

      {:ok, _} = Stars.toggle_star(old_starred, user)
      {:ok, _} = Stars.toggle_star(old_starred, user2)
      {:ok, _} = Stars.toggle_star(old_starred, user3)

      # Recent, 3 stars, long content, published recently (should be ignored)
      published_notebook =
        notebook_fixture(%{
          inserted_at: DateTools.days_ago(3),
          content: String.duplicate("d", 200),
          user_id: user.id
        })

      {:ok, _} = Stars.toggle_star(published_notebook, user)
      {:ok, _} = Stars.toggle_star(published_notebook, user2)
      {:ok, _} = Stars.toggle_star(published_notebook, user3)

      publish_log_fixture(%{
        notebook_id: published_notebook.id,
        platform: "x",
        inserted_at: DateTools.days_ago(2)
      })

      # Recent, 3 stars, short content (should be ignored)
      short_content_notebook =
        notebook_fixture(%{
          inserted_at: DateTools.days_ago(4),
          content: String.duplicate("e", 199),
          user_id: user.id
        })

      {:ok, _} = Stars.toggle_star(short_content_notebook, user)
      {:ok, _} = Stars.toggle_star(short_content_notebook, user2)
      {:ok, _} = Stars.toggle_star(short_content_notebook, user3)

      assert Stars.star_count(recent_starred) == 2
      assert Stars.starred?(recent_starred, user2)
      assert Stars.starred?(recent_starred, user3)
      assert recent_starred.content == String.duplicate("a", 200)

      # Recent, 3 stars, nil content (should be ignored)
      nil_content_notebook =
        notebook_fixture(%{
          inserted_at: DateTools.days_ago(4),
          content: nil,
          user_id: user.id
        })

      {:ok, _} = Stars.toggle_star(nil_content_notebook, user)
      {:ok, _} = Stars.toggle_star(nil_content_notebook, user2)
      {:ok, _} = Stars.toggle_star(nil_content_notebook, user3)

      # Check that the most starred notebook is the recent one
      most_starred = Notebooks.get_most_starred_recent_notebook("x")
      assert most_starred.id == recent_starred.id
      assert most_starred.user.id == recent_starred.user_id

      # Publish most_starred
      publish_log_fixture(%{
        notebook_id: most_starred.id,
        platform: "x",
        inserted_at: DateTools.days_ago(2)
      })

      most_starred2 = Notebooks.get_most_starred_recent_notebook("x")
      assert most_starred2.id == recent_less_starred.id

      # Publish most_starred2
      publish_log_fixture(%{
        notebook_id: most_starred2.id,
        platform: "x",
        inserted_at: DateTools.days_ago(2)
      })

      # Not any more recent notebooks
      refute Notebooks.get_most_starred_recent_notebook("x")
    end

    test "returns nil when no notebooks meet the criteria", %{user: user} do
      # Older, starred, long content
      _old_starred =
        notebook_fixture(%{
          inserted_at: DateTools.days_ago(15),
          content: String.duplicate("c", 200),
          user_id: user.id
        })

      # Recent, starred, long content, but published
      published_notebook =
        notebook_fixture(%{
          inserted_at: DateTools.days_ago(3),
          content: String.duplicate("d", 200),
          user_id: user.id
        })

      publish_log_fixture(%{
        notebook_id: published_notebook.id,
        platform: "x",
        inserted_at: DateTools.days_ago(2)
      })

      # Recent, starred, but short content
      _short_content_notebook =
        notebook_fixture(%{
          inserted_at: DateTools.days_ago(4),
          content: String.duplicate("e", 199),
          user_id: user.id
        })

      assert Notebooks.get_most_starred_recent_notebook("x") == nil
    end

    test "handles notebooks published to platforms other than 'x'", %{
      user: user,
      user2: user2
    } do
      target_notebook =
        notebook_fixture(%{
          inserted_at: DateTools.days_ago(7),
          content: String.duplicate("a", 200),
          user_id: user.id
        })

      {:ok, _} = Stars.toggle_star(target_notebook, user2)

      publish_log_fixture(%{
        notebook_id: target_notebook.id,
        platform: "linkedin",
        inserted_at: DateTools.days_ago(2)
      })

      most_starred = Notebooks.get_most_starred_recent_notebook("x")
      assert most_starred.id == target_notebook.id
    end
  end
end
