defmodule Notesclub.Repo.Migrations.AddRunInLivebookCountToNotebooks do
  use Ecto.Migration

  def change do
    alter table(:notebooks) do
      add :run_in_livebook_count, :integer, default: 0, null: false
    end
  end
end
