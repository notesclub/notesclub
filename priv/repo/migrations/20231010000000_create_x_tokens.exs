defmodule Notesclub.Repo.Migrations.CreateXTokens do
  use Ecto.Migration

  def change do
    create table(:x_tokens) do
      add :access_token, :text, null: false
      add :refresh_token, :text
      add :last_used_at, :utc_datetime, null: false

      timestamps()
    end
  end
end
