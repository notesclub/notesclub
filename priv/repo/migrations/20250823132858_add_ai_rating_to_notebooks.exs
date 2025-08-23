defmodule Notesclub.Repo.Migrations.AddAiRatingToNotebooks do
  use Ecto.Migration

  def change do
    alter table(:notebooks) do
      add :ai_rating, :integer
    end
  end
end
