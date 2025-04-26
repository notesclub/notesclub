defmodule Notesclub.X.XTokens.XToken do
  @moduledoc """
  Schema for storing X API access tokens
  """
  use TypedEctoSchema
  import Ecto.Changeset

  alias Notesclub.Repo
  alias Notesclub.X.XToken

  typed_schema "x_tokens" do
    field :access_token, :string
    field :refresh_token, :string, default: nil
    field :last_used_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:access_token, :refresh_token, :last_used_at])
    |> validate_required([:access_token, :last_used_at])
  end
end
