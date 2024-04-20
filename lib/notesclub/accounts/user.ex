defmodule Notesclub.Accounts.User do
  @moduledoc """
  User schema
  """

  use TypedEctoSchema
  import Ecto.Changeset

  typed_schema "users" do
    field :username, :string
    field :avatar_url, :string
    field :github_id, :integer
    field :name, :string
    field :twitter_username, :string
    has_many :notebooks, Notesclub.Notebooks.Notebook
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :avatar_url, :github_id, :twitter_username, :name])
    |> validate_required([:username])
    |> unique_constraint(:username)
  end
end
