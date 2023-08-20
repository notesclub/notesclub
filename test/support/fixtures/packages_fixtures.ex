defmodule Notesclub.PackagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notesclub.Packages` context.
  """

  @doc """
  Generate a package.
  """
  def package_fixture(attrs \\ %{}) do
    {:ok, package} =
      attrs
      |> Enum.into(%{
        name: Faker.Internet.user_name()
      })
      |> Notesclub.Packages.create_package()

    package
  end
end
