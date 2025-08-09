defmodule Notesclub.Repo.Migrations.UpgradeObanProTo16 do
  use Ecto.Migration

  def up, do: Oban.Pro.Migration.up(version: "1.6.0")

  def down, do: Oban.Pro.Migration.down(version: "1.6.0")
end
