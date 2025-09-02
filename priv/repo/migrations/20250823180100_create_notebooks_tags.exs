defmodule Notesclub.Repo.Migrations.CreateNotebooksTags do
  use Ecto.Migration

  def change do
    create table(:notebooks_tags) do
      add(:notebook_id, references(:notebooks, on_delete: :delete_all), null: false)
      add(:tag_id, references(:tags, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:notebooks_tags, [:notebook_id]))
    create(index(:notebooks_tags, [:tag_id]))
    create(unique_index(:notebooks_tags, [:notebook_id, :tag_id]))
  end
end
