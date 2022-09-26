defmodule Notesclub.Repo.Migrations.ContentTypeString do
  use Ecto.Migration

  def up do
    alter table(:notebooks) do
      modify :content, :text
    end
  end

  def down do
    alter table(:notebooks) do
      modify :content, :binary
    end
  end
end
