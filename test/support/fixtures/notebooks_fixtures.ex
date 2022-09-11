defmodule Notesclub.NotebooksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notesclub.Notebooks` context.
  """

  @doc """
  Generate a unique notebook github_html_url.
  """
  def unique_notebook_github_html_url, do: "some github_html_url#{System.unique_integer([:positive])}"

  @doc """
  Generate a notebook.
  """
  def notebook_fixture(attrs \\ %{}) do
    repo = Notesclub.ReposFixtures.repo_fixture()
    {:ok, notebook} =
      attrs
      |> Enum.into(%{
        github_filename: "some github_filename",
        github_html_url: unique_notebook_github_html_url(),
        github_owner_avatar_url: "some github_owner_avatar_url",
        github_owner_login: "some github_owner_login",
        github_repo_name: "some github_repo_name",
        repo_id: repo.id,
        user_id: repo.user_id
      })
      |> Notesclub.Notebooks.create_notebook()

    notebook
  end
end
