defmodule NotesclubWeb.NotebookLive.Index.NotebookComponent do
  use NotesclubWeb, :live_component

  alias Notesclub.StringTools
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook

  defp truncated_title(notebook) do
    StringTools.truncate(notebook.title, 50)
  end

  defp truncated_filename(notebook) do
    StringTools.truncate(notebook.github_filename, 50)
  end

  defp search_fragment(assigns) do
    ~H"""
    <%= if assigns[:search] && !String.contains?(@notebook.github_filename, @search) do %>
      <p class="text-gray-400">
        <%= Notebooks.content_fragment(@notebook, @search) %>
      </p>
    <% end %>
    """
  end

  defp format_date(%Notebook{inserted_at: inserted_at}) do
    %NaiveDateTime{year: year, month: month, day: day} = inserted_at
    "#{year}-#{month}-#{day}"
  end
end
