defmodule Notesclub.Repo.Migrations.AddNewFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:bio, :string)
      add(:email, :string)
      add(:location, :string)
      add(:followers_count, :integer, default: 0)
      add(:last_login_at, :utc_datetime)
    end
  end
end
