defmodule Notesclub.Repos.Repo do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Notesclub.Accounts.User

  @timestamps_opts []

  typed_schema "repos" do
    field :name, :string
    field :full_name, :string
    field :default_branch, :string
    field :fork, :boolean

    belongs_to :user, User

    timestamps()
  end

  @doc """
  Update changeset
  We can NOT make :default_branch required
  because GithubAPI.get/1 does NOT return it
  RepoSyncWorker sets it later in an update
  """
  def create_changeset(repo, attrs) do
    repo
    |> cast(attrs, [:name, :user_id, :full_name, :default_branch, :fork])
    |> validate_required([:name, :full_name, :fork])
    |> unique_constraint([:name, :user_id, :full_name])
  end

  @doc false
  def update_changeset(repo, attrs) do
    repo
    |> create_changeset(attrs)
    |> validate_required(:default_branch)
  end
end
