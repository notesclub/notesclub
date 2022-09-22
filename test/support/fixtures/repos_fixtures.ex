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

    username = Faker.Internet.user_name()
    repo_name = Faker.Internet.user_name()

    {:ok, repo} =
      attrs
      |> Enum.into(%{
        name: username,
        full_name: "#{username}/#{repo_name}",
        default_branch: Faker.Internet.user_name(),
        fork: false,
        user_id: user.id
      })
      |> Notesclub.Repos.create_repo()

    repo
  end
end
