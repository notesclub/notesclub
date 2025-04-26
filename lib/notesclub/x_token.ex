defmodule Notesclub.XToken do
  @moduledoc """
  Schema for storing X API access tokens
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Notesclub.Repo
  alias Notesclub.XToken

  schema "x_tokens" do
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

  @doc """
  Returns the most recent X API token.
  """
  def get_latest_token do
    XToken
    |> last(:inserted_at)
    |> Repo.one()
  end

  @doc """
  Creates a new X API token.
  """
  def create_token(attrs \\ %{}) do
    attrs = Map.put(attrs, :last_used_at, DateTime.utc_now())

    %XToken{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the last_used_at field for a token.
  """
  def mark_token_used(token) do
    token
    |> changeset(%{last_used_at: DateTime.utc_now()})
    |> Repo.update()
  end
end
