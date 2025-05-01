defmodule Notesclub.X.XTokens do
  @moduledoc """
  Context for X tokens
  """
  import Ecto.Query, warn: false

  alias Notesclub.Repo
  alias Notesclub.X.XToken

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
    |> XToken.changeset(attrs)
    |> Repo.insert()
  end

  def update_token(token, attrs) do
    token
    |> XToken.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the last_used_at field for a token.
  """
  def mark_token_used(token) do
    token
    |> XToken.changeset(%{last_used_at: DateTime.utc_now()})
    |> Repo.update()
  end
end
