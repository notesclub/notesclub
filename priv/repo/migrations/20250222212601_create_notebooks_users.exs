defmodule Notesclub.Repo.Migrations.CreateNotebooksUsers do
  use Ecto.Migration

  def change do
    create table(:notebooks_users) do
      add :notebook_id, references(:notebooks, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:notebooks_users, [:notebook_id, :user_id])
    create index(:notebooks_users, [:user_id])
  end
end
