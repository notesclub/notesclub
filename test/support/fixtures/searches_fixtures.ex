defmodule Notesclub.SearchesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notesclub.Searches` context.
  """

  @doc """
  Generate a search.
  """
  def search_fixture(attrs \\ %{}) do
    {:ok, search} =
      attrs
      |> Enum.into(%{
        order: ":asc",
        page: 2,
        per_page: 10,
        response_body: %{},
        response_headers: %{},
        response_notebooks_count: 10,
        response_private: %{},
        response_status: 42,
        url: "https://github.com/..."
      })
      |> Notesclub.Searches.create_search()

    search
  end
end
