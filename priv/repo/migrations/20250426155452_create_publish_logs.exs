defmodule Notesclub.Repo.Migrations.CreatePublishLogs do
  use Ecto.Migration

  def change do
    create table(:publish_logs) do
      add :platform, :string
      add :notebook_id, references(:notebooks, on_delete: :delete_all)

      timestamps()
    end

    create index(:publish_logs, [:notebook_id])
  end
end
