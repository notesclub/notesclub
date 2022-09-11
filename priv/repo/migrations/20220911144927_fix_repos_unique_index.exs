defmodule Notesclub.Repo.Migrations.FixReposUniqueIndex do
  use Ecto.Migration

  def change do
    drop unique_index(:repos, [:name])
    create unique_index(:repos, [:name, :user_id])
  end
end
