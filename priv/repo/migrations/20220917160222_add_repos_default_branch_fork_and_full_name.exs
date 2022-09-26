defmodule Notesclub.Repo.Migrations.AddReposDefaultBranchForkAndFullName do
  use Ecto.Migration

  def change do
    alter table("repos") do
      add :default_branch, :string
      add :fork, :boolean
      add :full_name, :string
    end

    create unique_index(:repos, [:full_name])
  end
end
