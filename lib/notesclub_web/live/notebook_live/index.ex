defmodule NotesclubWeb.NotebookLive.Index do
  use NotesclubWeb, :live_view
  use Phoenix.HTML
  import Phoenix.LiveView.Helpers
  import Phoenix.LiveView

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook

  @per_page 20

  def per_page, do: @per_page

  def mount(_params, _session, socket) do
    {:ok, assign(socket, notebooks_count: Notebooks.count())}
  end

  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    run_action(params, live_action, socket)
  end

  defp run_action(%{"repo" => repo, "author" => author}, :repo, socket) do
    socket = assign(socket, author: author, repo: repo)
    notebooks = get_notebooks(socket, :repo, 0)
    {:noreply, assign(socket, search: nil, notebooks: notebooks)}
  end

  defp run_action(%{"author" => author}, :author, socket) do
    socket = assign(socket, author: author, repo: nil)
    notebooks = get_notebooks(socket, :author, 0)
    {:noreply, assign(socket, search: nil, notebooks: notebooks)}
  end

  defp run_action(%{"q" => search} = args, :search, socket) do
    # We get_notebooks/3 needs :search and :notebooks in the socket
    socket = assign(socket, search: search, notebooks: [])
    notebooks = get_notebooks(socket, :search, 0)

    {:noreply,
     assign(socket, page: 0, search: search, notebooks: notebooks, author: nil, repo: nil)}
  end

  defp run_action(_params, :home, socket) do
    notebooks = get_notebooks(socket, :home, 0)
    {:noreply, assign(socket, page: 0, notebooks: notebooks, search: nil, author: nil, repo: nil)}
  end

  defp run_action(_params, :random, socket) do
    notebooks = get_notebooks(socket, :random, 0)
    {:noreply, assign(socket, page: 0, notebooks: notebooks, search: nil, author: nil, repo: nil)}
  end

  def handle_event("search", %{"q" => ""}, socket) do
    {:noreply, push_patch(socket, to: Routes.notebook_index_path(socket, :home))}
  end

  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, push_patch(socket, to: Routes.notebook_index_path(socket, :search, q: q))}
  end

  def handle_event("random", _, socket) do
    {:noreply, push_patch(socket, to: Routes.notebook_index_path(socket, :random))}
  end

  def handle_event("load-more", _, socket) do
    %{assigns: %{page: page, notebooks: notebooks, live_action: live_action}} = socket

    next_page = page + 1

    {:noreply,
     assign(
       socket,
       notebooks: notebooks ++ get_notebooks(socket, live_action, next_page),
       page: next_page
     )}
  end

  defp format_date(%Notebook{inserted_at: inserted_at}) do
    %NaiveDateTime{year: year, month: month, day: day} = inserted_at
    "#{year}-#{month}-#{day}"
  end

  defp get_notebooks(_socket, :home, page) do
    Notebooks.list_notebooks(per_page: @per_page, page: page, order: :desc)
  end

  defp get_notebooks(_socket, :random, page) do
    Notebooks.list_notebooks(per_page: @per_page, page: page, order: :random)
  end

  defp get_notebooks(%{assigns: %{repo: repo, author: author}}, :repo, page) do
    Notebooks.list_notebooks(
      github_repo_name: repo,
      github_owner_login: author,
      per_page: @per_page,
      page: page,
      order: :desc
    )
  end

  defp get_notebooks(%{assigns: %{author: author}}, :author, page) do
    Notebooks.list_notebooks(
      github_owner_login: author,
      per_page: @per_page,
      page: page,
      order: :desc
    )
  end

  defp get_notebooks(%{assigns: %{search: search, notebooks: notebooks}}, :search, page) do
    per_page = trunc(@per_page / 2)
    exclude_ids = Enum.map(notebooks, & &1.id)

    filename_matches =
      Notebooks.list_notebooks(
        github_filename: search,
        per_page: per_page,
        page: page,
        order: :desc,
        exclude_ids: exclude_ids
      )

    exclude_ids = exclude_ids ++ Enum.map(filename_matches, & &1.id)

    content_matches =
      Notebooks.list_notebooks(
        content: search,
        per_page: per_page,
        page: page,
        order: :desc,
        exclude_ids: exclude_ids
      )

    filename_matches ++ content_matches
  end
end
