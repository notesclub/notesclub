defmodule Notesclub.Repo.Migrations.CreateSearches do
  use Ecto.Migration

  def change do
    create table(:searches) do
      add :per_page, :integer
      add :page, :integer
      add :order, :string
      add :url, :string
      add :response_notebooks_count, :integer
      add :response_status, :integer
      add :response_body, :map
      add :response_headers, :map
      add :response_private, :map

      timestamps()
    end
  end
end
