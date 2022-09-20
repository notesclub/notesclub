defmodule Notesclub.Repos do
  @moduledoc """
  The Repos context.
  """

  import Ecto.Query, warn: false
  alias Notesclub.Repo

  alias Notesclub.Repos.Repo, as: RepoSchema
  alias Notesclub.Workers.RepoSyncWorker

  require Logger

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
    attrs
    |> Enum.into(%{
      default_branch: nil,
      name: nil,
      full_name: nil,
      fork: nil
    })
    |> create_repo_and_enqueue_sync_if_necessary()
  end

  defp create_repo_and_enqueue_sync_if_necessary(%{default_branch: nil} = attrs), do: create_repo_and_enqueue_sync(attrs)
  defp create_repo_and_enqueue_sync_if_necessary(%{name: nil} = attrs), do: create_repo_and_enqueue_sync(attrs)
  defp create_repo_and_enqueue_sync_if_necessary(%{full_name: nil} = attrs), do: create_repo_and_enqueue_sync(attrs)
  defp create_repo_and_enqueue_sync_if_necessary(%{fork: nil} = attrs), do: create_repo_and_enqueue_sync(attrs)

  defp create_repo_and_enqueue_sync_if_necessary(attrs) do
    # All fields — no need to enqueue sync
    %RepoSchema{}
    |> RepoSchema.changeset(attrs)
    |> Repo.insert()
  end

  defp create_repo_and_enqueue_sync(attrs) do
    changeset = RepoSchema.changeset(%RepoSchema{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:repo, changeset)
    |> Ecto.Multi.insert(
      :repo_default_branch_worker,
      fn %{
        repo: %RepoSchema{
          id: repo_id
        }
      } ->
        RepoSyncWorker.new(%{repo_id: repo_id})
      end)
    |> Repo.transaction()
    |> case do
      {:ok, %{repo: repo}} ->
        {:ok, repo}
      {:error, :repo, changeset, _} ->
        {:error, changeset}
      {:error, :repo_default_branch_worker, changeset, _} ->
        Logger.error "create_repo failed in repo_default_branch_worker. This should never happen. attrs: #{inspect(attrs)}"
        {:error, changeset}
      end
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
    |> Repo.update()
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
