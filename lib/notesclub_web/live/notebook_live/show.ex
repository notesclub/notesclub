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

    is_starred =
      if socket.assigns.current_user,
        do: Notebooks.is_starred?(notebook, socket.assigns.current_user),
        else: false

    share_to_x_text = "#{notebook.title}#{name_or_username(notebook.user)} #{uri} #myelixirstatus"

    {:noreply,
     assign(
       socket,
       notebook: notebook,
       clap_count: notebook.clap_count,
       share_to_x_text: share_to_x_text,
       is_starred: is_starred
     )}
  end

  defp name_or_username(nil), do: ""
  defp name_or_username(%{twitter_username: nil, name: nil} = user), do: " by #{user.username}"
  defp name_or_username(%{twitter_username: nil} = user), do: " by #{user.name}"
  defp name_or_username(%{twitter_username: twitter_username}), do: " by @#{twitter_username}"

  def handle_event("clap", params, socket) do
    notebook_id = params["notebook_id"] || params["notebook-id"]
    %{assigns: %{clap_count: clap_count}} = socket

    {:ok, _} =
      notebook_id
      |> String.to_integer()
      |> ClapServer.increase_count()

    {:noreply, assign(socket, clap_count: clap_count + 1)}
  end

  def handle_event("toggle-star", _params, %{assigns: %{current_user: nil}} = socket) do
    {:noreply,
     socket
     |> put_flash(:error, "You need to log in to star notebooks")}
  end

  def handle_event(
        "toggle-star",
        _params,
        %{assigns: %{notebook: notebook, current_user: current_user}} = socket
      ) do
    Notebooks.toggle_star(notebook, current_user)
    {:noreply, assign(socket, :is_starred, Notebooks.is_starred?(notebook, current_user))}
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
