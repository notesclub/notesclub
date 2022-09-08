defmodule Notesclub.Repos do
  @moduledoc """
  The Repos context.
  """

  import Ecto.Query, warn: false
  alias Notesclub.Repo

  alias Notesclub.Repos.Repo, as: RepoSchema

  @doc """
  Returns the list of repos.

  ## Examples

      iex> list_repos()
      [%RepoSchema{}, ...]

  """
  def list_repos do
    Repo.all(RepoSchema)
  end

  @doc """
  Gets a single repo.

  Raises `Ecto.NoResultsError` if the Repo does not exist.

  ## Examples

      iex> get_repo!(123)
      %RepoSchema{}

      iex> get_repo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_repo!(id), do: Repo.get!(RepoSchema, id)

  @doc """
  Creates a repo.

  ## Examples

      iex> create_repo(%{field: value})
      {:ok, %RepoSchema{}}

      iex> create_repo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_repo(attrs \\ %{}) do
    %RepoSchema{}
    |> RepoSchema.changeset(attrs)
    |> RepoSchema.insert()
  end

  @doc """
  Updates a repo.

  ## Examples

      iex> update_repo(repo, %{field: new_value})
      {:ok, %RepoSchema{}}

      iex> update_repo(repo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_repo(%RepoSchema{} = repo, attrs) do
    repo
    |> RepoSchema.changeset(attrs)
    |> RepoSchema.update()
  end

  @doc """
  Deletes a repo.

  ## Examples

      iex> delete_repo(repo)
      {:ok, %RepoSchema{}}

      iex> delete_repo(repo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_repo(%RepoSchema{} = repo) do
    Repo.delete(repo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking repo changes.

  ## Examples

      iex> change_repo(repo)
      %Ecto.Changeset{data: %Repo{}}

  """
  def change_repo(%RepoSchema{} = repo, attrs \\ %{}) do
    RepoSchema.changeset(repo, attrs)
  end

  @doc """
  Returns an `{:ok, %Ecto.Changeset{}}` for repo by repo name and user id.

  ## Examples

      iex> get_by_name_and_user_id(%{user_id: "id", name: "repo_name"})
      {:ok, %RepoSchema{}}

  """
  def get_by_name_and_user_id(attrs) do
    Repo.get_by(RepoSchema, attrs)
  end
end
