defmodule Notesclub.Accounts.User do
  @moduledoc """
  User schema
  """

  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts []

  typed_schema "users" do
    field :username, :string
    field :avatar_url, :string
    field :github_id, :integer
    field :name, :string
    field :twitter_username, :string
    field :bio, :string
    field :email, :string
    field :location, :string
    field :followers_count, :integer, default: 0
    field :last_login_at, :utc_datetime
    has_many :notebooks, Notesclub.Notebooks.Notebook
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :username,
      :avatar_url,
      :github_id,
      :twitter_username,
      :name,
      :bio,
      :email,
      :location,
      :followers_count,
      :last_login_at
    ])
    |> validate_required([:username])
    |> unique_constraint(:username)
  end
end
