defmodule Notesclub.Repo.Migrations.CreateNotebooks do
  use Ecto.Migration

  def change do
    create table(:notebooks) do
      add :github_filename, :string
      add :github_html_url, :string
      add :github_owner_login, :string
      add :github_owner_avatar_url, :string
      add :github_repo_name, :string

      timestamps()
    end

    create unique_index(:notebooks, [:github_html_url])
  end
end
