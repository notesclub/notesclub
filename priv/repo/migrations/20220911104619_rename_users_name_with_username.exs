defmodule Notesclub.Repo.Migrations.RenameReposNameWithUsername do
  use Ecto.Migration

  def change do
    drop unique_index(:users, [:name])
    rename table(:users), :name, to: :username
    create unique_index(:users, [:username])
  end
end
