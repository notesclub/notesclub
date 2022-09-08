defmodule Notesclub.ReposFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notesclub.Repos` context.
  """

  @doc """
  Generate a repo.
  """
  def repo_fixture(attrs \\ %{}) do
    {:ok, repo} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Notesclub.Repos.create_repo()

    repo
  end
end
