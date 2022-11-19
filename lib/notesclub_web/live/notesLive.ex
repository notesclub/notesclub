defmodule NotesclubWeb.NotesLive do
  use NotesclubWeb, :live_view
  use Phoenix.HTML
  import Phoenix.LiveView.Helpers
  import Phoenix.LiveView

  alias NotesclubWeb.NotesLive
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook

  @notebooks_in_home_count 7
  def notebooks_in_home_count, do: @notebooks_in_home_count

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("search", %{"term" => term}, socket) do
    {:noreply, push_patch(socket, to: Routes.notes_path(socket, :all, search: term))}
  end

  def handle_event("random", _, socket) do
    {:noreply, push_patch(socket, to: Routes.live_path(socket, NotesLive))}
  end

  def handle_params(%{"author" => author, "repo" => repo}, _url, socket) do
    notebooks = Notebooks.list_repo_author_notebooks_desc(repo, author)
    count = Notebooks.count()

    {:noreply,
     assign(socket, notebooks: notebooks, notebooks_count: count, search: nil, page: :repo)}
  end

  def handle_params(%{"author" => author}, _url, socket) do
    notebooks = Notebooks.list_author_notebooks_desc(author)
    count = Notebooks.count()

    {:noreply,
     assign(socket, notebooks: notebooks, notebooks_count: count, search: nil, page: :author)}
  end

  def handle_params(%{"search" => "content:" <> term}, _url, socket) do
    notebooks = Notebooks.list_notebooks(github_filename: term)

    notebooks2 =
      Notebooks.list_notebooks(content: term, exclude_ids: notebooks |> Enum.map(& &1.id))

    count = Notebooks.count()

    {:noreply,
     assign(socket,
       notebooks: notebooks ++ notebooks2,
       notebooks_count: count,
       search: term,
       page: :all
     )}
  end

  def handle_params(%{"search" => term}, _url, socket) do
    notebooks = Notebooks.list_notebooks(github_filename: term)
    count = Notebooks.count()

    {:noreply,
     assign(socket, notebooks: notebooks, notebooks_count: count, search: term, page: :all)}
  end

  def handle_params(%{}, _url, %{assigns: %{live_action: :last_week}} = socket) do
    notebooks = Notebooks.list_notebooks_since(7)
    count = Notebooks.count()

    {:noreply,
     assign(socket,
       notebooks: notebooks,
       notebooks_count: count,
       search: nil,
       page: :last_week
     )}
  end

  def handle_params(%{}, _url, %{assigns: %{live_action: :last_month}} = socket) do
    notebooks = Notebooks.list_notebooks_since(30)
    count = Notebooks.count()

    {:noreply,
     assign(socket,
       notebooks: notebooks,
       notebooks_count: count,
       search: nil,
       page: :last_month
     )}
  end

  def handle_params(%{}, _url, %{assigns: %{live_action: :all}} = socket) do
    notebooks = Notebooks.list_notebooks()
    count = Notebooks.count()

    {:noreply,
     assign(socket, notebooks: notebooks, notebooks_count: count, search: nil, page: :all)}
  end

  def handle_params(%{}, _url, socket) do
    notebooks = Notebooks.list_random_notebooks(%{limit: @notebooks_in_home_count})
    count = Notebooks.count()

    {:noreply,
     assign(socket, notebooks: notebooks, notebooks_count: count, search: nil, page: :random)}
  end

  defp format_date(%Notebook{inserted_at: inserted_at}) do
    %NaiveDateTime{year: year, month: month, day: day} = inserted_at
    "#{year}-#{month}-#{day}"
  end
end
