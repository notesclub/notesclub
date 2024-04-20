defmodule Notesclub.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notesclub.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        username: Faker.Internet.user_name(),
        github_id: :rand.uniform(1_000_000)
      })
      |> Notesclub.Accounts.create_user()

    user
  end
end
