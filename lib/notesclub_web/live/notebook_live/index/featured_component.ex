defmodule NotesclubWeb.NotebookLive.Index.FeaturedComponent do
  @moduledoc """
  Badges of featured users
  """

  use NotesclubWeb, :live_component

  alias Notesclub.Tags

  @initial_visible_count 8

  @impl true
  def update(assigns, socket) do
    all_tags = Tags.list_tag_names()

    show_all_tags = Map.get(socket.assigns, :show_all_tags, false)

    tags_to_show =
      if show_all_tags do
        all_tags
      else
        Enum.take(all_tags, @initial_visible_count)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(all_tags: all_tags, tags_to_show: tags_to_show, show_all_tags: show_all_tags)}
  end

  @impl true
  def handle_event("show-all-tags", _params, socket) do
    {:noreply, assign(socket, show_all_tags: true, tags_to_show: socket.assigns.all_tags)}
  end

  @impl true
  def handle_event("dont-show-all-tags", _params, socket) do
    tags = Enum.take(Tags.list_tag_names(), @initial_visible_count)
    {:noreply, assign(socket, show_all_tags: false, tags_to_show: tags, all_tags: tags)}
  end
end
