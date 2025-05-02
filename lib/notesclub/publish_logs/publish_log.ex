defmodule Notesclub.PublishLogs.PublishLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "publish_logs" do
    field :platform, :string

    belongs_to :notebook, Notesclub.Notebooks.Notebook

    timestamps()
  end

  @doc false
  def changeset(publish_log, attrs) do
    publish_log
    |> cast(attrs, [:platform, :notebook_id])
    |> validate_required([:platform])
  end
end
