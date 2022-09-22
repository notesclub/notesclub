defmodule Notesclub.Repo.Migrations.AddNotebooksUrl do
  use Ecto.Migration

  def change do
    alter table("notebooks") do
      add :url, :string
    end
  end
end
