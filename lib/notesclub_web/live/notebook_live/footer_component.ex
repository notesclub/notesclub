defmodule NotesclubWeb.NotebookLive.FooterComponent do
  use NotesclubWeb, :live_component

  alias Notesclub.Notebooks

  def mount(socket) do
    {:ok, assign(socket, notebooks_count: Notebooks.count())}
  end
end
