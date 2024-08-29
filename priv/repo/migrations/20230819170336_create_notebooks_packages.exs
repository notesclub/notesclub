defmodule Notesclub.Repo.Migrations.CreateNotebooksPackages do
  use Ecto.Migration

  def change do
    create table(:notebooks_packages) do
      add(:package_id, references(:packages, on_delete: :nothing), null: false)
      add(:notebook_id, references(:notebooks, on_delete: :nothing), null: false)
    end

    create(index(:notebooks_packages, [:package_id]))
    create(index(:notebooks_packages, [:notebook_id]))
    create(unique_index(:notebooks_packages, [:package_id, :notebook_id]))
  end
end
