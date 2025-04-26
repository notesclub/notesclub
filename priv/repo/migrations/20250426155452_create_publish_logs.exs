defmodule Notesclub.Repo.Migrations.CreatePublishLogs do
  use Ecto.Migration

  def change do
    create table(:publish_logs) do
      add :platform, :string
      add :notebook_id, references(:notebooks, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:publish_logs, [:notebook_id])
    create index(:publish_logs, [:user_id])
  end
end
