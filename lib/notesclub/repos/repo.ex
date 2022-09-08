defmodule Notesclub.Repos.Repo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "repos" do
    field :name, :string
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(repo, attrs) do
    repo
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
