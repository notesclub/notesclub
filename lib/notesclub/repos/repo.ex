defmodule Notesclub.Repos.Repo do
  use Ecto.Schema
  import Ecto.Changeset
  alias Notesclub.Accounts.User

  schema "repos" do
    field :name, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(repo, attrs) do
    repo
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
