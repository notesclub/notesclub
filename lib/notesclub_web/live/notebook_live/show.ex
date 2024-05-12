defmodule NotesclubWeb.NotebookLive.Show do
  use NotesclubWeb, :live_view
  use PhoenixHTMLHelpers
  import Phoenix.Component

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.ClapServer
  alias Notesclub.Notebooks.Paths
  alias NotesclubWeb.NotebookLive.ShareComponent
  alias NotesclubWeb.NotebookLive.Show.Livemd
  alias Phoenix.LiveView.Socket

  # This can raise an exception and render 404
  # so we add the typespec no_return() so Dialyzer doesn't complain
  @spec handle_params(map(), binary(), Socket.t()) :: no_return()
  def handle_params(_params, uri, socket) do
    path = String.replace(uri, ~r/https?:\/\/[^\/]+/, "")
    url = Paths.path_to_url(path) |> URI.decode()
    notebook = Notebooks.get_by!(url: url, preload: [:user, :repo])
    username = get_username(notebook.user)
    share_to_x_text = "#{notebook.title} by #{name_or_username} #{uri} #myelixirstatus"

    {:noreply, assign(
      socket,
      notebook: notebook,
      clap_count: notebook.clap_count,
      share_to_x_text: share_to_x_text)
    }
  end

  def handle_event("clap", params, socket) do
    notebook_id = params["notebook_id"] || params["notebook-id"]
    %{assigns: %{clap_count: clap_count}} = socket

    {:ok, _} =
      notebook_id
      |> String.to_integer()
      |> ClapServer.increase_count()

    {:noreply, assign(socket, clap_count: clap_count + 1)}
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

  defp get_username(user) do
    case user.twitter_username do
      nil -> user.username
      _ -> user.twitter_username
    end
  end
end
