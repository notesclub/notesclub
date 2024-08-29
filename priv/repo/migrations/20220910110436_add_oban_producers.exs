defmodule Notesclub.Repo.Migrations.AddObanProducers do
  use Ecto.Migration

  def change do
    #  Comment to avoid warning: warning: Oban.Pro.Migrations.Producers.change/0 is undefined (module Oban.Pro.Migrations.Producers is not available or is yet to be defined)
    # if Code.ensure_loaded?(Oban.Pro.Migrations.Producers) do
    #   Oban.Pro.Migrations.Producers.change()
    # else
    #   :ignored
    # end
  end
end
