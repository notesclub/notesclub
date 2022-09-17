defmodule Notesclub.Repos.Repo do
  use Ecto.Schema
  import Ecto.Changeset
  alias Notesclub.Accounts.User

  schema "repos" do
    field :name, :string
    field :full_name, :string
    field :default_branch, :string
    field :fork, :boolean

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(repo, attrs) do
    repo
    |> cast(attrs, [:name, :user_id, :full_name, :default_branch, :fork])
    |> validate_required([:name])
    |> unique_constraint([:name, :user_id, :full_name])
  end
end
