defmodule Notesclub.Notebooks do
  @moduledoc """
  The Notebooks context.
  """

  import Ecto.Query, warn: false
  alias Notesclub.Repo

  alias Notesclub.Notebooks.Notebook

  @doc """
  Returns the list of notebooks.

  ## Examples

      iex> list_notebooks()
      [%Notebook{}, ...]

  """
  def list_notebooks() do
    Repo.all(Notebook)
  end

  def list_notebooks_desc do
    from(n in Notebook,
      order_by: -n.id)
    |> Repo.all()
  end

  @doc """
  Returns the notebooks from an author in desc order

  ## Examples

      iex> list_author_notebooks_desc("someone")
      [%Notebook{}, ...]

  """
  def list_author_notebooks_desc(author) when is_binary(author) do
    from(n in Notebook,
      where: n.github_owner_login == ^author,
      order_by: -n.id)
    |> Repo.all()
  end

  @doc """
  Returns the notebooks within a repo in desc order

  ## Examples

      iex> list_repo_author_notebooks_desc("my_repo", "my_login")
      [%Notebook{}, ...]

  """
  def list_repo_author_notebooks_desc(repo_name, author_login) when is_binary(repo_name) and is_binary(author_login) do
    from(n in Notebook,
      where: n.github_repo_name == ^repo_name,
      where: n.github_owner_login == ^author_login,
      order_by: -n.id)
    |> Repo.all()
  end

  @doc """
  Returns a list of random notebooks

  ## Examples

      iex> list_random_notebooks(%{limit: 2}
      [%Notebook{}, %Notebook{}]

  """
  def list_random_notebooks(%{limit: limit}) do
    from(n in Notebook,
      order_by: fragment("RANDOM()"),
      limit: ^limit)
    |> Repo.all()
  end

  @doc """
  Gets a single notebook.

  Raises `Ecto.NoResultsError` if the Notebook does not exist.

  ## Examples

      iex> get_notebook!(123)
      %Notebook{}

      iex> get_notebook!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notebook!(id), do: Repo.get!(Notebook, id)

  @doc """
  Gets a notebook by its filename, owner and repo
  This allows us to override a file if the url has changed

  ## Examples
    iex> get_by_filename_owner_and_repo?(%{url: "https://github.com/.../file.livemd"})
    true

  TODO: We should probably deprecate this once we re-download all public livemd files within
        each repo's default branch and their history of blobs.
        Then, we won't create new files but update
  """
  def get_by_filename_owner_and_repo(filename, owner_login, repo_name)
   when is_binary(filename) and is_binary(owner_login) and is_binary(repo_name) do
    from(n in Notebook,
      where: n.github_filename == ^filename,
      where: n.github_owner_login == ^owner_login,
      where: n.github_repo_name == ^repo_name,
      limit: 1)
    |> Repo.one()
  end

  @doc """
  Creates a notebook.

  ## Examples

      iex> create_notebook(%{field: value})
      {:ok, %Notebook{}}

      iex> create_notebook(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notebook(attrs \\ %{}) do
    %Notebook{}
    |> Notebook.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a notebook.

  ## Examples

      iex> update_notebook(notebook, %{field: new_value})
      {:ok, %Notebook{}}

      iex> update_notebook(notebook, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notebook(%Notebook{} = notebook, attrs) do
    notebook
    |> Notebook.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notebook.

  ## Examples

      iex> delete_notebook(notebook)
      {:ok, %Notebook{}}

      iex> delete_notebook(notebook)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notebook(%Notebook{} = notebook) do
    Repo.delete(notebook)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notebook changes.

  ## Examples

      iex> change_notebook(notebook)
      %Ecto.Changeset{data: %Notebook{}}

  """
  def change_notebook(%Notebook{} = notebook, attrs \\ %{}) do
    Notebook.changeset(notebook, attrs)
  end

  @spec count :: number
  def count() do
    from(n in Notebook,
      select: count(n.id))
    |> Repo.one()
  end
end
