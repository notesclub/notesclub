defmodule Notesclub.Notebooks.NotebookUser do
  @moduledoc """
  Represents the join table between notebooks and users for starring.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "notebooks_users" do
    belongs_to :notebook, Notesclub.Notebooks.Notebook
    belongs_to :user, Notesclub.Accounts.User

    timestamps()
  end

  def changeset(notebook_user, attrs) do
    notebook_user
    |> cast(attrs, [:notebook_id, :user_id])
    |> validate_required([:notebook_id, :user_id])
    |> unique_constraint([:notebook_id, :user_id])
  end
end
