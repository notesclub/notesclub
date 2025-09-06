defmodule Notesclub.Tags.Tag do
  @moduledoc """
  Tag schema
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Notesclub.Notebooks.Notebook
  alias Notesclub.NotebooksTags.NotebookTag

  @timestamps_opts []
  @valid_tag_names [
    "ai",
    "security",
    "iot",
    "tutorial",
    "beginner",
    "intermediate",
    "advanced",
    "gen-server",
    "otp",
    "data-science",
    "sql",
    "apis",
    "workshop",
    "testing",
    "debugging",
    "algorithms",
    "data-structures",
    "etl",
    "robotics"
  ]

  typed_schema "tags" do
    field(:name, :string)

    many_to_many(:notebooks, Notebook, join_through: NotebookTag)

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> update_change(:name, &normalize_name/1)
    |> validate_inclusion(:name, @valid_tag_names)
    |> unique_constraint(:name)
  end

  def valid_tag_names, do: @valid_tag_names

  defp normalize_name(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.downcase()
  end

  defp normalize_name(name), do: name
end
