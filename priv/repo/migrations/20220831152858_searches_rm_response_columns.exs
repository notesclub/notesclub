defmodule Notesclub.Repo.Migrations.SearchesRmResponseColumns do
  use Ecto.Migration

  def up do
    alter table("searches") do
      remove :response_body
      remove :response_headers
      remove :response_private
    end
  end

  def down do
    alter table("searches") do
      add :response_body, :map
      add :response_headers, :map
      add :response_private, :map
    end
  end
end
