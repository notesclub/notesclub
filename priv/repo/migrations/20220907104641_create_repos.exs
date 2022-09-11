defmodule Notesclub.Repo.Migrations.CreateRepos do
  use Ecto.Migration

  def change do
    create table(:repos) do
      add :name, :string
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:repos, [:user_id])
    create unique_index(:repos, [:name])
  end
end
