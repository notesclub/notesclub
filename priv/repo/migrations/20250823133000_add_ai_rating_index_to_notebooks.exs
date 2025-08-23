defmodule Notesclub.Repo.Migrations.AddAiRatingIndexToNotebooks do
  use Ecto.Migration

  def change do
    # Create index for ai_rating ordering with DESC NULLS LAST
    # This will optimize queries that order by ai_rating in descending order
    execute """
            CREATE INDEX IF NOT EXISTS notebooks_ai_rating_desc_nulls_last_idx
            ON notebooks (ai_rating DESC NULLS LAST);
            """,
            "DROP INDEX IF EXISTS notebooks_ai_rating_desc_nulls_last_idx;"
  end
end
