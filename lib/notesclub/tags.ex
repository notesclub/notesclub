defmodule Notesclub.Tags do
  @moduledoc """
  The Tags context.

  Responsible for CRUD on tags and linking tags to notebooks.
  """

  import Ecto.Query, warn: false
  alias Notesclub.Repo

  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Tags.Tag

  @doc """
  List all tags.
  """
  def list_tags do
    Repo.all(Tag)
  end

  def list_tag_names do
    Tag.valid_tag_names()
  end

  @doc """
  Get a tag by id.
  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Get tag by name.
  """
  @spec get_by_name(binary) :: Tag.t() | nil
  def get_by_name(name) do
    Repo.get_by(Tag, name: normalize(name))
  end

  @doc """
  Get tag by name with optional preloads.
  """
  @spec get_by_name(binary, list) :: Tag.t() | nil
  def get_by_name(name, preload: tables) do
    tag = Repo.get_by(Tag, name: normalize(name))
    tag && Repo.preload(tag, tables)
  end

  @doc """
  Get or create tag by name.
  """
  @spec get_or_create_by_name(binary) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_by_name(name) when is_binary(name) do
    normalized = normalize(name)

    case Repo.get_by(Tag, name: normalized) do
      nil -> create_tag(%{name: normalized})
      %Tag{} = tag -> {:ok, tag}
    end
  end

  @doc """
  Create tag.
  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Create or fetch multiple tags by name, returning {:ok, tags} or :error.
  """
  @spec list_or_create_by_names([binary]) :: {:ok, [Tag.t()]} | :error
  def list_or_create_by_names(names) when is_list(names) do
    tags = Enum.map(names, &get_or_create_by_name/1)

    if Enum.all?(tags, &(elem(&1, 0) == :ok)) do
      {:ok, Enum.map(tags, &elem(&1, 1))}
    else
      :error
    end
  end

  @doc """
  Link a notebook to the given tags list (Tag structs). Notebook must have :tags preloaded.
  """
  @spec link!(Notebook.t(), [Tag.t()]) :: :ok | {:error, Ecto.Changeset.t()}
  def link!(%Notebook{} = notebook, tags) when is_list(tags) do
    notebook_changeset =
      notebook
      |> Notebook.changeset(%{})
      |> Ecto.Changeset.put_assoc(:tags, tags)

    case Repo.update(notebook_changeset) do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Link a notebook to tags by their names. Creates missing tags as needed.

  Accepts a `Notebook` and a list of tag names (binaries). Names are normalized
  and created if they don't exist, then associated with the notebook by
  replacing existing tag associations.
  """
  @spec link_tags_to_notebook(Notebook.t(), [binary]) :: :ok | {:error, term()}
  def link_tags_to_notebook(%Notebook{} = notebook, tag_names) when is_list(tag_names) do
    with {:ok, tags} <- list_or_create_by_names(tag_names) do
      notebook
      |> Repo.preload(:tags)
      |> link!(tags)
    end
  end

  defp normalize(name) do
    name
    |> String.trim()
    |> String.downcase()
  end
end
