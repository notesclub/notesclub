defmodule Notesclub.Notebooks do
  @moduledoc """
  The Notebooks context.
  """

  import Ecto.Query, warn: false
  alias Notesclub.Repo

  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Repos
  alias Notesclub.Repos.Repo, as: RepoSchema

  @doc """
  Returns the list of notebooks.

  ## Examples

      iex> list_notebooks()
      [%Notebook{}, ...]

  """
  def list_notebooks(opts \\ []) do
    Enum.reduce(opts, from(n in Notebook), fn
      {:order, :desc}, query ->
        order_by(query, [notebook], -notebook.id)

      {:github_filename, github_filename}, query ->
        search = "%#{github_filename}%"
        where(query, [notebook], ilike(notebook.github_filename, ^search))

      {:repo_id, repo_id}, query ->
        where(query, [notebook], notebook.repo_id == ^repo_id)

      _, query ->
        query
    end)
    |> Repo.all()
  end

  def list_notebooks_since(num_days_ago) when is_integer(num_days_ago) do
    from(n in Notebook,
      where: n.inserted_at >= from_now(-(^num_days_ago), "day"),
      order_by: -n.id
    )
    |> Repo.all()
  end

  def reset_notebooks_url(%RepoSchema{id: repo_id, default_branch: default_branch}) do
    %{repo_id: repo_id}
    |> list_notebooks()
    |> Enum.reduce(Ecto.Multi.new(), fn
      %Notebook{} = notebook, query ->
        url = url_from_github_html_url(notebook.github_html_url, default_branch)
        changeset = Notebook.changeset(notebook, %{"url" => url})
        Ecto.Multi.update(query, "notebook_#{notebook.id}", changeset)

      _, query ->
        query
    end)
    |> Repo.transaction()
  end

  defp url_from_github_html_url(nil, _), do: nil
  defp url_from_github_html_url(_, nil), do: nil

  defp url_from_github_html_url(github_html_url, default_branch) when is_binary(default_branch) do
    String.replace(github_html_url, ~r/\/blob\/[^\/]*\//, "/blob/#{default_branch}/")
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
      order_by: -n.id
    )
    |> Repo.all()
  end

  @doc """
  Returns the notebooks within a repo in desc order

  ## Examples

      iex> list_repo_author_notebooks_desc("my_repo", "my_login")
      [%Notebook{}, ...]

  """
  def list_repo_author_notebooks_desc(repo_name, author_login)
      when is_binary(repo_name) and is_binary(author_login) do
    from(n in Notebook,
      where: n.github_repo_name == ^repo_name,
      where: n.github_owner_login == ^author_login,
      order_by: -n.id
    )
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
      limit: ^limit
    )
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

  def get_notebook!(id, preload: tables) do
    from(n in Notebook,
      where: n.id == ^id,
      preload: ^tables
    )
    |> Repo.one!()
  end

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
      limit: 1
    )
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
    |> Notebook.changeset(attrs |> add_fields() |> maybe_set_url())
    |> Repo.insert()
  end

  defp add_fields(attrs) do
    attrs
    |> Enum.into(%{
      repo_id: nil,
      github_html_url: nil,
      url: nil
    })
  end

  defp maybe_set_url(%{repo_id: nil} = attrs), do: attrs
  defp maybe_set_url(%{github_html_url: nil} = attrs), do: attrs

  defp maybe_set_url(%{url: nil} = attrs) do
    repo = Repos.get_repo!(attrs.repo_id)
    url = url_from_github_html_url(attrs.github_html_url, repo.default_branch)
    Map.put(attrs, :url, url)
  end

  defp maybe_set_url(attrs), do: attrs

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
      select: count(n.id)
    )
    |> Repo.one()
  end
end
