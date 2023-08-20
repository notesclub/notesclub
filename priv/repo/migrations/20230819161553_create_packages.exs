defmodule Notesclub.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add(:name, :string, null: false)

      timestamps()
    end

    create(unique_index(:packages, [:name]))
  end
end
