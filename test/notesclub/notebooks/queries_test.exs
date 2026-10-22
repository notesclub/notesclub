defmodule Notesclub.Notebooks.QueriesTest do
  use Notesclub.DataCase

  import Notesclub.AccountsFixtures
  import Notesclub.NotebooksFixtures
  import Notesclub.PackagesFixtures
  import Notesclub.ReposFixtures

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.NotebooksPackages
  alias Notesclub.Stars
  alias Notesclub.Tags

  test "starred notebooks are scoped to the reader, filtered, and paginated" do
    reader = user_fixture()
    other = user_fixture()
    first = notebook_fixture()
    second = notebook_fixture()
    empty = notebook_fixture(%{content: nil})
    {:ok, _} = Stars.toggle_star(first, reader)
    {:ok, _} = Stars.toggle_star(second, reader)
    {:ok, _} = Stars.toggle_star(empty, reader)
    {:ok, _} = Stars.toggle_star(first, other)

    assert length(Notebooks.list_starred_notebooks_by_user(reader)) == 3

    assert [%{id: id, user: %{id: _}}] =
             Notebooks.list_starred_notebooks_by_user(reader,
               exclude_ids: [first.id],
               require_content: true,
               per_page: 1,
               page: 0,
               preload: [:user],
               order: :desc
             )

    assert id == second.id
    assert length(Notebooks.list_starred_notebooks_by_user(reader, per_page: 1, page: 1)) == 1
    assert Enum.map(Notebooks.list_starred_notebooks_by_user(other), & &1.id) == [first.id]
    assert hd(Notebooks.list_notebooks(order: :star_count)).id == first.id
    assert Notebooks.get_star_count(first.id) == 2
  end

  test "author and repository lists are newest first and pagination omits earlier results" do
    first = notebook_fixture(%{github_owner_login: "author", github_repo_name: "repo"})
    second = notebook_fixture(%{github_owner_login: "author", github_repo_name: "repo"})
    notebook_fixture(%{github_owner_login: "other", github_repo_name: "repo"})

    assert Enum.map(Notebooks.list_author_notebooks_desc("author"), & &1.id) == [
             second.id,
             first.id
           ]

    assert Enum.map(Notebooks.list_repo_author_notebooks_desc("repo", "author"), & &1.id) == [
             second.id,
             first.id
           ]

    assert [%{id: id}] =
             Notebooks.list_notebooks(
               github_owner_login: "author",
               order: :desc,
               per_page: 1,
               page: 1
             )

    assert id == first.id
    assert length(Notebooks.list_notebooks(page: 0)) == 3
    assert length(Notebooks.list_random_notebooks(%{limit: 2})) == 2
  end

  test "empty searches and unknown optional filters preserve the catalog" do
    notebook = notebook_fixture()
    assert Notebooks.normalize_search_term(nil) == nil
    assert Notebooks.list_notebooks(full_text_search: "   ", order: :relevance) == []

    for opts <- [
          [full_text_search: nil, order: :relevance],
          [package_name: "missing"],
          [tag_name: "missing"]
        ] do
      assert [%{id: id}] = Notebooks.list_notebooks(opts)
      assert id == notebook.id
    end
  end

  test "content fragments and titles handle missing or non-heading content" do
    assert Notebooks.content_fragment(%Notebook{content: nil}, "word") == nil
    assert Notebooks.content_fragment(%Notebook{content: "word"}, nil) == nil
    assert Notebooks.content_fragment(%Notebook{content: "word"}, "") == nil
    assert Notebooks.extract_title(nil) == nil
    assert Notebooks.extract_title("plain text") == nil
  end

  test "related notebooks share packages and random recommendations require three packages" do
    first = notebook_fixture()
    second = notebook_fixture()
    third = notebook_fixture()
    packages = for name <- ["req", "jason", "ecto"], do: package_fixture(%{name: name})

    for notebook <- [first, second] do
      assert :ok = NotebooksPackages.link!(Repo.preload(notebook, :packages), packages)
    end

    assert :ok = NotebooksPackages.link!(Repo.preload(third, :packages), [hd(packages)])

    assert Enum.sort(Enum.map(Notebooks.get_related_by_packages(first), & &1.id)) ==
             Enum.sort([second.id, third.id])

    assert Enum.sort(Enum.map(Notebooks.get_random_notebooks(), & &1.id)) ==
             Enum.sort([first.id, second.id])
  end

  test "notebook creation resolves an existing repository from its full name" do
    repo = repo_fixture(%{name: "repo", full_name: "author/repo"})

    assert {:ok, notebook} =
             Notebooks.create_notebook(%{
               github_repo_name: "repo",
               github_owner_login: "author",
               github_filename: "book.livemd",
               github_owner_avatar_url: "https://example.com/avatar.png",
               github_html_url: "https://github.com/author/repo/blob/main/book.livemd"
             })

    assert notebook.repo_id == repo.id
    assert notebook.user_id == repo.user_id
  end

  test "analysis through the notebook context saves its tags and rating" do
    notebook = notebook_fixture()
    assert {:ok, rating, tags} = Notebooks.analyse_notebook(notebook)
    assert Notebooks.get_notebook!(notebook.id).ai_rating == rating
    assert Enum.sort(tags) == ["ai", "gen-server"]
  end

  test "tags normalize names, reuse existing records, and replace notebook associations" do
    notebook = notebook_fixture()
    assert {:ok, tag} = Tags.get_or_create_by_name(" TUTORIAL ")
    assert tag.name == "tutorial"
    assert Tags.get_tag!(tag.id) == tag
    assert tag in Tags.list_tags()
    assert {:ok, ^tag} = Tags.get_or_create_by_name("tutorial")
    assert :ok = Tags.link_tags_to_notebook(notebook, ["tutorial", "ai"])
    assert :ok = Tags.link_tags_to_notebook(notebook, ["ai"])
    assert [%{name: "ai"}] = Notebooks.get_notebook!(notebook.id, preload: :tags).tags
    assert :error = Tags.list_or_create_by_names(["not-a-valid-tag"])
  end
end
