defmodule Notesclub.NotebooksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notesclub.Notebooks` context.
  """

  @doc """
  Generate a notebook.
  """
  def notebook_fixture(attrs \\ %{}) do
    repo = Notesclub.ReposFixtures.repo_fixture()

    {:ok, notebook} =
      attrs
      |> Enum.into(%{
        github_filename: Faker.File.file_name(),
        github_html_url: "#{Faker.Internet.url()}/#{System.unique_integer([:positive])}", # We need a unique url
        url: Faker.Internet.url(),
        github_owner_avatar_url: Faker.Internet.url(),
        github_owner_login: Faker.Internet.user_name(),
        github_repo_name: Faker.Internet.user_name(),
        repo_id: repo.id,
        user_id: repo.user_id
      })
      |> Notesclub.Notebooks.create_notebook()

    notebook
  end
end
