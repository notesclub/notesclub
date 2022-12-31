defmodule Notesclub.Repo.Migrations.AddNameAndTwitterUsernameToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :name, :string
      add :twitter_username, :string
    end
  end
end
