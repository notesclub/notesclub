defmodule Notesclub.Packages.Package do
  @moduledoc """
  Schema for hex packages
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Notesclub.Notebooks.Notebook

  @timestamps_opts []

  typed_schema "packages" do
    field(:name, :string)

    many_to_many(:notebooks, Notebook, join_through: "notebooks_packages")

    timestamps()
  end

  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name, message: "Hex package name already exists")
  end
end
