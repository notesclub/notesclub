defmodule Notesclub.Repo.Migrations.RmNotebooksGithubApiResponse do
  use Ecto.Migration

  def change do
    alter table("notebooks") do
      remove :github_api_response
    end
  end
end
