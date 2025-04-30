defmodule NotesclubWeb.NotebookLive.Show do
  use NotesclubWeb, :live_view
  use PhoenixHTMLHelpers
  import Phoenix.Component

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Paths
  alias Notesclub.Stars
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

    starred =
      if socket.assigns.current_user,
        do: Stars.starred?(notebook, socket.assigns.current_user),
        else: false

    share_to_text =
      "#{notebook.title}#{name_or_username(notebook.user)} #{uri} #myelixirstatus"
      |> URI.encode_www_form()

    related_notebooks =
      Notebooks.get_related_by_packages(notebook, limit: 4, preload: [:user, :repo])

    ids = Enum.map(related_notebooks, & &1.id)
    num_random_notebooks = 7 - length(related_notebooks)

    related_notebooks =
      related_notebooks ++
        Notebooks.get_random_notebooks(
          exclude_ids: ids,
          limit: num_random_notebooks,
          preload: [:user, :repo]
        )

    {:noreply,
     assign(
       socket,
       notebook: notebook,
       star_count: Stars.star_count(notebook),
       share_to_text: share_to_text,
       related_notebooks: related_notebooks,
       search: nil,
       starred: starred
     )}
  end

  defp name_or_username(nil), do: ""
  defp name_or_username(%{twitter_username: nil, name: nil} = user), do: " by #{user.username}"
  defp name_or_username(%{twitter_username: nil} = user), do: " by #{user.name}"
  defp name_or_username(%{twitter_username: twitter_username}), do: " by @#{twitter_username}"

  def handle_event("toggle-star", _params, %{assigns: %{current_user: nil}} = socket) do
    {:noreply,
     socket
     |> put_flash(:error, "You need to log in to star notebooks")}
  end

  def handle_event("toggle-star", _params, socket) do
    %{
      assigns: %{
        notebook: notebook,
        current_user: current_user,
        star_count: star_count,
        starred: starred
      }
    } = socket

    case Stars.toggle_star(notebook, current_user) do
      {:ok, _} ->
        star_count = if starred, do: star_count - 1, else: star_count + 1

        socket =
          socket
          |> assign(:starred, !starred)
          |> assign(:star_count, star_count)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "There was an error. Please try again.")}
    end
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
