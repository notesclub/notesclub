defmodule NotesclubWeb.NotebookLive.Index.NotebookComponent do
  @moduledoc """
  Raw of the Index
  """

  use NotesclubWeb, :live_component

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Notebooks.Paths
  alias Notesclub.StringTools

  defp truncated_title(notebook) do
    StringTools.truncate(notebook.title, 50)
  end

  defp truncated_filename(notebook) do
    StringTools.truncate(notebook.github_filename, 50)
  end

  defp search_fragment(assigns) do
    ~H"""
    <%= if assigns[:search] && !String.contains?(@notebook.github_filename, extract_search_term(@search)) do %>
      <p class="text-gray-400">
        {Notebooks.content_fragment(@notebook, extract_search_term(@search))}
      </p>
    <% end %>
    """
  end

  defp extract_search_term(search) when is_binary(search) do
    if String.starts_with?(search, "\"") && String.ends_with?(search, "\"") do
      String.slice(search, 1..(String.length(search) - 2))
    else
      search
    end
  end

  defp notebook_path(notebook) do
    Paths.url_to_path(notebook)
  end

  defp format_date(%Notebook{inserted_at: inserted_at}) do
    %NaiveDateTime{year: year, month: month, day: day} = inserted_at
    "#{year}-#{month}-#{day}"
  end
end
