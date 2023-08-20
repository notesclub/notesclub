defmodule Notesclub.NotebooksPackages do
  @moduledoc """
  The NotebooksPackages context.

  This context is responsible for managing the relationship between notebooks and packages.
  """

  import Ecto.Query, warn: false
  alias Notesclub.Repo

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Packages
  alias Notesclub.Packages.Extractor
  alias Notesclub.Packages.Package

  @doc """
  Updates the packages associated with a notebook based on its content.

  ## Raises
    - Raises an error if the notebook does not exist or if there's an issue updating the notebook's packages.
  """
  @spec link_from_notebook!(integer) :: :ok
  def link_from_notebook!(notebook_id) do
    notebook = Notebooks.get_notebook!(notebook_id, preload: :packages)

    {:ok, packages} =
      notebook.content
      |> Extractor.extract_packages()
      |> Packages.list_or_create_by_names()

    link!(notebook, packages)
  end

  @doc """
  Links a notebook to a list of packages.

  ## Parameters
    - `notebook`: The notebook struct with its **packages preloaded**.
    - `packages`: A list of package structs to link with the notebook.

  ## Raises
    - Raises an error if there's an issue updating the notebook's packages.
  """
  @spec link!(Notebook.t(), [Package.t()]) :: :ok
  def link!(notebook, packages) do
    notebook_changeset =
      notebook
      |> Notebook.changeset(%{})
      |> Ecto.Changeset.put_assoc(:packages, packages)

    case Repo.update(notebook_changeset) do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
