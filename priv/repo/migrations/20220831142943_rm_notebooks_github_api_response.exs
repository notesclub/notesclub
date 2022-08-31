defmodule Notesclub.Repo.Migrations.RmNotebooksGithubApiResponse do
  use Ecto.Migration

  def up do
    alter table("notebooks") do
      remove :github_api_response
    end
  end

  def down do
    alter table("notebooks") do
      add :github_api_response, :map
    end
  end
end
