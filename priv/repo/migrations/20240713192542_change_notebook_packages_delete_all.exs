defmodule Notesclub.Repo.Migrations.ChangeNotebooksPackagesDeleteAll do
  use Ecto.Migration

  def up do
    drop(index(:notebooks_packages, [:package_id]))
    drop(index(:notebooks_packages, [:notebook_id]))
    drop(unique_index(:notebooks_packages, [:package_id, :notebook_id]))

    execute "ALTER TABLE notebooks_packages DROP CONSTRAINT notebooks_packages_package_id_fkey"
    execute "ALTER TABLE notebooks_packages DROP CONSTRAINT notebooks_packages_notebook_id_fkey"

    alter table(:notebooks_packages) do
      modify(:package_id, references(:packages, on_delete: :delete_all), null: false)
      modify(:notebook_id, references(:notebooks, on_delete: :delete_all), null: false)
    end

    create(index(:notebooks_packages, [:package_id]))
    create(index(:notebooks_packages, [:notebook_id]))
    create(unique_index(:notebooks_packages, [:package_id, :notebook_id]))
  end

  def down do
    drop(index(:notebooks_packages, [:package_id]))
    drop(index(:notebooks_packages, [:notebook_id]))
    drop(unique_index(:notebooks_packages, [:package_id, :notebook_id]))

    execute "ALTER TABLE notebooks_packages DROP CONSTRAINT notebooks_packages_package_id_fkey"
    execute "ALTER TABLE notebooks_packages DROP CONSTRAINT notebooks_packages_notebook_id_fkey"

    alter table(:notebooks_packages) do
      modify(:package_id, references(:packages, on_delete: :nothing), null: false)
      modify(:notebook_id, references(:notebooks, on_delete: :nothing), null: false)
    end

    create(index(:notebooks_packages, [:package_id]))
    create(index(:notebooks_packages, [:notebook_id]))
    create(unique_index(:notebooks_packages, [:package_id, :notebook_id]))
  end
end
