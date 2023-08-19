defmodule Notesclub.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add :name, :string

      timestamps()
    end
  end
end
