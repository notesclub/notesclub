defmodule Notesclub.Repo.Migrations.RemoveClapCountFromNotebooks do
  use Ecto.Migration

  def change do
    alter table(:notebooks) do
      remove :clap_count
    end
  end
end
