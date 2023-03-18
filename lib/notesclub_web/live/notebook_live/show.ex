defmodule NotesclubWeb.NotebookLive.Show do
  use NotesclubWeb, :live_view
  use Phoenix.HTML
  import Phoenix.Component

  alias Notesclub.Notebooks

  def handle_params(_params, uri, socket) do
    path = String.replace(uri, ~r/https?:\/\/[^\/]+/, "")
    notebook = Notebooks.get_by!(url: "https://github.com#{path}", preload: [:user, :repo])
    {:noreply, assign(socket, notebook: notebook)}
  end

  defp file(notebook) do
    file_with_path =
      String.replace(notebook.url, ~r/https:\/\/github.com\/[^\/]+\/[^\/]+\/[^\/]+\/[^\/]+\//, "")

    if String.length(file_with_path) > 40 do
      notebook.github_filename
    else
      file_with_path
    end
  end
end
