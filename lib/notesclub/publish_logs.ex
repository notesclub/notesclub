defmodule Notesclub.PublishLogs do
  @moduledoc """
  Stores a log of the notebooks shared on X
  so we don't duplicate posts
  """

  import Ecto.Query, warn: false
  alias Notesclub.Repo

  alias Notesclub.PublishLogs.PublishLog

  @doc """
  Returns the list of publish_logs.

  ## Examples

      iex> list_publish_logs()
      [%PublishLog{}, ...]

  """
  def list_publish_logs do
    Repo.all(PublishLog)
  end

  @doc """
  Gets a single publish_log.

  Raises `Ecto.NoResultsError` if the Publish log does not exist.

  ## Examples

      iex> get_publish_log!(123)
      %PublishLog{}

      iex> get_publish_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_publish_log!(id), do: Repo.get!(PublishLog, id)

  @doc """
  Creates a publish_log.

  ## Examples

      iex> create_publish_log(%{field: value})
      {:ok, %PublishLog{}}

      iex> create_publish_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_publish_log(attrs \\ %{}) do
    %PublishLog{}
    |> PublishLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a publish_log.

  ## Examples

      iex> update_publish_log(publish_log, %{field: new_value})
      {:ok, %PublishLog{}}

      iex> update_publish_log(publish_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_publish_log(%PublishLog{} = publish_log, attrs) do
    publish_log
    |> PublishLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a publish_log.

  ## Examples

      iex> delete_publish_log(publish_log)
      {:ok, %PublishLog{}}

      iex> delete_publish_log(publish_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_publish_log(%PublishLog{} = publish_log) do
    Repo.delete(publish_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking publish_log changes.

  ## Examples

      iex> change_publish_log(publish_log)
      %Ecto.Changeset{data: %PublishLog{}}

  """
  def change_publish_log(%PublishLog{} = publish_log, attrs \\ %{}) do
    PublishLog.changeset(publish_log, attrs)
  end
end
