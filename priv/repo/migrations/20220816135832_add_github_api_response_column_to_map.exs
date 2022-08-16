defmodule Notesclub.Repo.Migrations.AddGithubApiResponseColumnToMap do
  use Ecto.Migration

  def change do
    alter table("notebooks") do
      add :github_api_response, :map
    end
  end
end
