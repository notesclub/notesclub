defmodule Notesclub.Repo.Migrations.DeleteSearchesTable do
  use Ecto.Migration

  def up do
    alter table("notebooks") do
      remove :search_id
    end

    drop table("searches")
  end

  def down do
    alter table("notebooks") do
      add :search_id, references("searches", on_delete: :nilify_all)
    end

    create table(:searches) do
      add :per_page, :integer
      add :page, :integer
      add :order, :string
      add :url, :string
      add :response_notebooks_count, :integer
      add :response_status, :integer

      timestamps()
    end
  end
end
