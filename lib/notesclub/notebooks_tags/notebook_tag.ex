defmodule Notesclub.NotebooksTags.NotebookTag do
  @moduledoc """
  Join schema for notebooks and tags
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Tags.Tag

  @timestamps_opts []

  typed_schema "notebooks_tags" do
    belongs_to(:notebook, Notebook)
    belongs_to(:tag, Tag)

    timestamps()
  end

  @doc false
  def changeset(notebook_tag, attrs) do
    notebook_tag
    |> cast(attrs, [:notebook_id, :tag_id])
    |> validate_required([:notebook_id, :tag_id])
  end
end
