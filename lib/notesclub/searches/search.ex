defmodule Notesclub.Searches.Search do
  use Ecto.Schema
  import Ecto.Changeset

  alias Notesclub.Notebooks.Notebook

  schema "searches" do
    field :order, :string
    field :page, :integer
    field :per_page, :integer
    field :response_body, :map
    field :response_headers, :map
    field :response_notebooks_count, :integer
    field :response_private, :map
    field :response_status, :integer
    field :url, :string
    has_many :notebooks, Notebook

    timestamps()
  end

  @doc false
  def changeset(search, attrs) do
    search
    |> cast(attrs, [:per_page, :page, :order, :url, :response_notebooks_count, :response_status, :response_body, :response_headers, :response_private])
    |> validate_required([:per_page, :page, :order, :url, :response_notebooks_count, :response_status, :response_body, :response_headers, :response_private])
  end
end
