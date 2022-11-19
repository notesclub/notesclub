defmodule NotesclubWeb.NotesLive do
  use NotesclubWeb, :live_view
  use Phoenix.HTML
  import Phoenix.LiveView.Helpers
  import Phoenix.LiveView

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook

  @random_notebooks_count 7
  @per_page 20

  def random_notebooks_count, do: @random_notebooks_count

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"author" => author, "repo" => repo}, _url, socket) do
    notebooks = Notebooks.list_repo_author_notebooks_desc(repo, author)
    count = Notebooks.count()

    {:noreply,
     assign(socket,
       notebooks: notebooks,
       notebooks_count: count,
       search: nil,
       page: :repo,
       page_number: 1
     )}
  end

  def handle_params(%{"author" => author}, _url, socket) do
    notebooks = Notebooks.list_author_notebooks_desc(author)
    count = Notebooks.count()

    {:noreply,
     assign(socket,
       notebooks: notebooks,
       notebooks_count: count,
       search: nil,
       page: :author,
       page_number: 1
     )}
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
       page: :all,
       page_number: 1
     )}
  end

  def handle_params(%{"search" => term}, _url, socket) do
    notebooks = Notebooks.list_notebooks(github_filename: term)
    count = Notebooks.count()

    {:noreply,
     assign(socket,
       notebooks: notebooks,
       notebooks_count: count,
       search: term,
       page: :all,
       page_number: 1
     )}
  end

  def handle_params(%{}, _url, %{assigns: %{live_action: :home}} = socket) do
    notebooks = get_notebooks()
    count = Notebooks.count()

    {:noreply,
     assign(socket,
       notebooks: notebooks,
       notebooks_count: count,
       search: nil,
       page: :last_week,
       page_number: 1
     )}
  end

  def handle_params(%{}, _url, %{assigns: %{live_action: :random}} = socket) do
    notebooks = Notebooks.list_random_notebooks(%{limit: @random_notebooks_count})
    count = Notebooks.count()

    {:noreply,
     assign(socket, notebooks: notebooks, notebooks_count: count, search: nil, page: :random)}
  end

  def handle_event("search", %{"term" => term}, socket) do
    {:noreply, push_patch(socket, to: Routes.notes_path(socket, :all, search: term))}
  end

  def handle_event("random", _, socket) do
    {:noreply, push_patch(socket, to: Routes.notes_path(socket, :random))}
  end

  def handle_event("load-more", _, socket) do
    %{assigns: %{page_number: page_number, notebooks: notebooks}} = socket
    next_page = page_number + 1

    {:noreply,
     assign(
       socket,
       notebooks: notebooks ++ get_notebooks(next_page),
       page_number: next_page
     )}
  end

  defp format_date(%Notebook{inserted_at: inserted_at}) do
    %NaiveDateTime{year: year, month: month, day: day} = inserted_at
    "#{year}-#{month}-#{day}"
  end

  defp get_notebooks(page_number \\ 1) do
    Notebooks.list_notebooks(per_page: @per_page, page: page_number, order: :desc)
  end
end
