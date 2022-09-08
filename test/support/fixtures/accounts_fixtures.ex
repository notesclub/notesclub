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
        name: "some name"
      })
      |> Notesclub.Accounts.create_user()

    user
  end
end
