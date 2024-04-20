defmodule Notesclub.Repo.Migrations.AddGithubIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :github_id, :integer
    end
  end
end
