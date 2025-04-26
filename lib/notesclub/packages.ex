defmodule Notesclub.Packages do
  @moduledoc """
  The Packages context.
  """

  import Ecto.Query, warn: false

  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Packages.Package
  alias Notesclub.Repo

  @doc """
  Returns the list of packages.

  ## Examples

      iex> list_packages()
      [%Package{}, ...]

  """
  def list_packages do
    Repo.all(Package)
  end

  def list_package_names do
    Repo.all(from p in Package, select: p.name)
  end

  @doc """
  Gets a single package.

  Raises `Ecto.NoResultsError` if the Package does not exist.

  ## Examples

      iex> get_package!(123)
      %Package{}

      iex> get_package!(456)
      ** (Ecto.NoResultsError)

  """
  def get_package!(id), do: Repo.get!(Package, id)

  @doc """
  Fetches a package by its name

  ## Examples
      iex> get_by_name("SomeName")
      %Package{name: "SomeName"}

      iex> get_by_name("NonExistentName")
      nil
  """
  @spec get_by_name(binary) :: Package.t() | nil
  def get_by_name(name) do
    Repo.get_by(Package, name: name)
  end

  @spec get_by_name(binary, list) :: Package.t() | nil
  def get_by_name(name, preload: tables) do
    package = Repo.get_by(Package, name: name)
    package && Repo.preload(package, tables)
  end

  @doc """
  Gets a package by its name. If it doesn't exist, creates a new package with the given name.

  ## Examples

      iex> get_or_create_by_name("SomeName")
      {:ok, %Package{name: "SomeName"}}

      iex> get_or_create_by_name("ExistingName")
      {:ok, %Package{name: "ExistingName"}}

  """
  @spec get_or_create_by_name(binary) :: {:ok, Package.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_by_name(name) when is_binary(name) do
    case get_by_name(name) do
      nil -> create_package(%{name: name})
      package -> {:ok, package}
    end
  end

  def list_or_create_by_names(names) do
    packages = Enum.map(names, &get_or_create_by_name/1)

    if Enum.all?(packages, &(elem(&1, 0) == :ok)) do
      {:ok, Enum.map(packages, &elem(&1, 1))}
    else
      :error
    end
  end

  @doc """
  Creates a package.

  ## Examples

      iex> create_package(%{field: value})
      {:ok, %Package{}}

      iex> create_package(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_package(attrs \\ %{}) do
    %Package{}
    |> Package.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a package.

  ## Examples

      iex> update_package(package, %{field: new_value})
      {:ok, %Package{}}

      iex> update_package(package, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_package(%Package{} = package, attrs) do
    package
    |> Package.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a package.

  ## Examples

      iex> delete_package(package)
      {:ok, %Package{}}

      iex> delete_package(package)
      {:error, %Ecto.Changeset{}}

  """
  def delete_package(%Package{} = package) do
    Repo.delete(package)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking package changes.

  ## Examples

      iex> change_package(package)
      %Ecto.Changeset{data: %Package{}}

  """
  def change_package(%Package{} = package, attrs \\ %{}) do
    Package.changeset(package, attrs)
  end

  def list_packages_with_last_notebook_url do
    last_notebook_query =
      from(np in "notebooks_packages",
        join: n in Notebook,
        on: n.id == np.notebook_id,
        order_by: [desc: n.id],
        distinct: np.package_id,
        select: %{
          notebook_id: n.id,
          package_id: np.package_id,
          notebook_inserted_at: n.inserted_at
        }
      )

    from(p in Package,
      inner_join: ln in subquery(last_notebook_query),
      on: ln.package_id == p.id,
      select: {p.name, ln.notebook_inserted_at},
      order_by: [desc: ln.notebook_id]
    )
    |> Repo.all()
  end
end
