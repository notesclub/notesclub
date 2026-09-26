defmodule Notesclub.Repo.Migrations.UpgradeObanProTo18 do
  use Ecto.Migration

  def up do
    if System.get_env("NOTESCLUB_IS_OBAN_PRO_ENABLED") == "true" do
      Oban.Pro.Migration.up(version: "1.8.0")
    end
  end

  def down do
    if System.get_env("NOTESCLUB_IS_OBAN_PRO_ENABLED") == "true" do
      Oban.Pro.Migration.down(version: "1.8.0")
    end
  end
end
