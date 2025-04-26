defmodule Notesclub.PublishLogs.PublishLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "publish_logs" do
    field :platform, :string
    field :notebook_id, :id
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(publish_log, attrs) do
    publish_log
    |> cast(attrs, [:platform])
    |> validate_required([:platform])
  end
end
