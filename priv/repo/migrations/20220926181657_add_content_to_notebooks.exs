defmodule Notesclub.Repo.Migrations.AddContentToNotebooks do
  use Ecto.Migration

  def change do
    alter table("notebooks") do
      add :content, :binary
    end
  end
end
