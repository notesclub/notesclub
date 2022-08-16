defmodule Notesclub.Notebooks.Notebook do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notebooks" do
    field :github_filename, :string
    field :github_owner_login, :string
    field :github_repo_name, :string
    field :github_html_url, :string
    field :github_owner_avatar_url, :string

    timestamps()
  end

  @doc false
  def changeset(notebook, attrs) do
    notebook
    |> cast(attrs, [:github_filename, :github_html_url, :github_owner_login, :github_owner_avatar_url, :github_repo_name])
    |> validate_required([:github_filename, :github_html_url, :github_owner_login, :github_owner_avatar_url, :github_repo_name])
    |> unique_constraint(:github_html_url)
  end
end
