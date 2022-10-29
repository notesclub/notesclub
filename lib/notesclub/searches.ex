defmodule Notesclub.Searches do
  @moduledoc """
  The Searches context.
  """

  import Ecto.Query, warn: false
  alias Notesclub.Repo

  alias Notesclub.Searches.Search

  @doc """
  Returns the list of searches.

  ## Examples

      iex> list_searches()
      [%Search{}, ...]

  """
  def list_searches do
    Repo.all(Search)
  end

  @doc """
  Gets a single search.

  Raises `Ecto.NoResultsError` if the Search does not exist.

  ## Examples

      iex> get_search!(123)
      %Search{}

      iex> get_search!(456)
      ** (Ecto.NoResultsError)

  """
  def get_search!(id), do: Repo.get!(Search, id)

  def get_last_search_from_today() do
    from(s in Search,
      order_by: -s.id,
      limit: 1,
      where: fragment("?::date", s.inserted_at) == ^Date.utc_today()
    )
    |> Repo.one()
  end

  @doc """
  Creates a search.

  ## Examples

      iex> create_search(%{field: value})
      {:ok, %Search{}}

      iex> create_search(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_search(attrs \\ %{}) do
    %Search{}
    |> Search.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a search.

  ## Examples

      iex> update_search(search, %{field: new_value})
      {:ok, %Search{}}

      iex> update_search(search, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_search(%Search{} = search, attrs) do
    search
    |> Search.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a search.

  ## Examples

      iex> delete_search(search)
      {:ok, %Search{}}

      iex> delete_search(search)
      {:error, %Ecto.Changeset{}}

  """
  def delete_search(%Search{} = search) do
    Repo.delete(search)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking search changes.

  ## Examples

      iex> change_search(search)
      %Ecto.Changeset{data: %Search{}}

  """
  def change_search(%Search{} = search, attrs \\ %{}) do
    Search.changeset(search, attrs)
  end

  @doc """
  Returns a tuple {integer, nil}, integer is the number of records
  being deleted by this query.

  ## Examples

      iex> delete_by_date(timestamps)
     {non_neg_integer, nil}

  """
  def delete_by_date(timestamps) do
    from(s in Search,
      where: s.inserted_at < ^timestamps
    )
    |> Repo.delete_all()
  end

  def notebooks_by_user(user) do
    data = Notesclub.GithubAPI.get(username: user.username, per_page: 100, page: 1, order: "asc")
    {:ok, ""}
  end
end
