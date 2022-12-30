defmodule Notesclub.Repo.Migrations.AddTwitterUsernameToUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :twitter_username, :string
    end
  end
end
