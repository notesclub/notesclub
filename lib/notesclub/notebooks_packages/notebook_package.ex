defmodule Notesclub.NotebooksPackages.NotebookPackage do
  @moduledoc """
  NotebookPackage schema
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Packages.Package

  typed_schema "notebooks_packages" do
    belongs_to(:notebook, Notebook)
    belongs_to(:package, Package)
  end

  @doc false
  def changeset(notebook_package, attrs) do
    notebook_package
    |> cast(attrs, [:notebook_id, :package_id])
    |> validate_required([:notebook_id, :package_id])
  end
end
