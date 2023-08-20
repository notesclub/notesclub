defmodule Notesclub.Notebooks.Notebook do
  @moduledoc """
  Notebook schema
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Notesclub.Accounts.User
  alias Notesclub.Packages.Package
  alias Notesclub.Repos.Repo

  @optional ~w(inserted_at user_id repo_id url content title run_in_livebook_count)a
  @required ~w(github_filename github_html_url github_owner_login github_owner_avatar_url github_repo_name)a

  typed_schema "notebooks" do
    field(:url, :string)
    field(:content, :string)
    field(:title, :string, default: "")

    # url to commit — provided by Github Search API
    field(:github_html_url, :string)
    field(:github_owner_avatar_url, :string)
    field(:github_filename, :string)
    field(:github_owner_login, :string)
    field(:github_repo_name, :string)
    field(:run_in_livebook_count, :integer, default: 0)

    belongs_to(:user, User)
    belongs_to(:repo, Repo)

    many_to_many(
      :packages,
      Package,
      join_through: "notebooks_packages",
      on_replace: :delete
    )

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
