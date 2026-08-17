defmodule Notesclub.Repo.Migrations.AddGithubOwnerIdToNotebooks do
  use Ecto.Migration

  def up do
    alter table(:notebooks) do
      add :github_owner_id, :integer
    end

    create index(:notebooks, [:github_owner_id])

    flush()

    # Backfill with the GitHub account that owns each notebook.
    # github_owner_login is the login we saw on the last sync, so the user with
    # that username is the owner — from now on we keep the immutable id too.
    execute """
    UPDATE notebooks
    SET github_owner_id = users.github_id
    FROM users
    WHERE notebooks.github_owner_login = users.username
      AND users.github_id IS NOT NULL
    """
  end

  def down do
    drop index(:notebooks, [:github_owner_id])

    alter table(:notebooks) do
      remove :github_owner_id
    end
  end
end
