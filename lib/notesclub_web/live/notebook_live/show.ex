defmodule NotesclubWeb.NotebookLive.Show do
  use NotesclubWeb, :live_view
  use Phoenix.HTML
  import Phoenix.Component

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Urls
  alias Phoenix.LiveView.Socket

  # This can raise an exception and render 404
  # so we add the typespec no_return() so Dialyzer doesn't complain
  @spec handle_params(map(), binary(), Socket.t()) :: no_return()
  def handle_params(_params, uri, socket) do
    path = String.replace(uri, ~r/https?:\/\/[^\/]+/, "")
    url = Urls.path_to_url(path)
    notebook = Notebooks.get_by!(url: url, preload: [:user, :repo])
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
