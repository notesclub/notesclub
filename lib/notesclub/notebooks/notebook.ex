defmodule Notesclub.Notebooks.Notebook do
  use Ecto.Schema
  import Ecto.Changeset

  alias Notesclub.Searches.Search
  alias Notesclub.Accounts.User
  alias Notesclub.Repos.Repo

  @optional ~w(search_id inserted_at user_id repo_id url)a
  @required ~w(github_filename github_html_url github_owner_login github_owner_avatar_url github_repo_name)a

  schema "notebooks" do
    field :github_filename, :string
    field :github_owner_login, :string
    field :github_repo_name, :string
    field :github_html_url, :string
    # url to default branch
    field :url, :string
    # url to commit — provided by Github Search API
    field :github_owner_avatar_url, :string

    belongs_to :search, Search
    belongs_to :user, User
    belongs_to :repo, Repo

    timestamps()
  end

  @doc false
  def changeset(notebook, attrs) do
    notebook
    |> cast(attrs, @optional ++ @required)
    |> validate_required(@required)
    |> unique_constraint(:github_html_url)
  end
end
