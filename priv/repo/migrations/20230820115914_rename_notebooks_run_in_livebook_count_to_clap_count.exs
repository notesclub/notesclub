defmodule Notesclub.Repo.Migrations.RenameNotebooksRunInLivebookCountToClapCount do
  use Ecto.Migration

  def change do
    rename(table(:notebooks), :run_in_livebook_count, to: :clap_count)
  end
end
