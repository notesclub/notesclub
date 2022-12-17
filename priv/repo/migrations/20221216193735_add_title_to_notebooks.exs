defmodule Notesclub.Repo.Migrations.AddTitleToNotebooks do
  use Ecto.Migration

  def change do
    alter table(:notebooks) do
      add :title, :string
    end
  end
end
