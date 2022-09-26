defmodule Notesclub.Repo.Migrations.AddObanProducers do
  use Ecto.Migration

  def change do
    if Code.ensure_loaded?(Oban.Pro.Migrations.Producers) do
      Oban.Pro.Migrations.Producers.change()
    else
      :ignored
    end
  end
end
