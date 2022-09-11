defmodule Notesclub.ReposFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notesclub.Repos` context.
  """

  @doc """
  Generate a repo.
  """
  def repo_fixture(attrs \\ %{}) do
    user = Notesclub.AccountsFixtures.user_fixture()

    {:ok, repo} =
      attrs
      |> Enum.into(%{
        name: Faker.Person.En.first_name(),
        user_id: user.id
      })
      |> Notesclub.Repos.create_repo()

    repo
  end
end
