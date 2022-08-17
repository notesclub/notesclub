defmodule Notesclub.Repo.Migrations.AddSearchIdToNotebooks do
  use Ecto.Migration

  def change do
    alter table("notebooks") do
      add :search_id, references("searches", on_delete: :nilify_all)
    end
  end
end
