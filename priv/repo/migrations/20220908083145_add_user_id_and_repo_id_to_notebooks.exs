defmodule Notesclub.Repo.Migrations.AddUserIdAndRepoIdToNotebooks do
  use Ecto.Migration

  def change do
    alter table("notebooks") do
      add :user_id, references(:users, on_delete: :nilify_all)
      add :repo_id, references(:repos, on_delete: :nilify_all)
    end

    create index(:notebooks, [:user_id])
    create index(:notebooks, [:repo_id])
  end
end
