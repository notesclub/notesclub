defmodule Notesclub.X.XToken do
  @moduledoc """
  Schema for storing X API access tokens
  """
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts []

  typed_schema "x_tokens" do
    field :access_token, :string
    field :refresh_token, :string, default: nil
    field :last_used_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(x_token, attrs) do
    x_token
    |> cast(attrs, [:access_token, :refresh_token, :last_used_at])
    |> validate_required([:access_token, :last_used_at])
  end
end
