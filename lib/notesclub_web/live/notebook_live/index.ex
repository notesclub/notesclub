defmodule NotesclubWeb.NotebookLive.Index do
  use NotesclubWeb, :live_view
  use Phoenix.HTML
  import Phoenix.Component
  import Phoenix.LiveView

  alias Notesclub.Accounts
  alias Notesclub.Notebooks

  @per_page 20

  def per_page, do: @per_page

  def mount(_params, _session, socket) do
    {:ok, assign(socket, last_search_time: 0, notebooks_count: Notebooks.count())}
  end

  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    run_action(params, live_action, socket)
  end

  defp run_action(%{"package" => package}, :package, socket) do
    socket = assign(socket, package: package, author: nil, repo: nil)
    notebooks = get_notebooks(socket, :package, 0, [])
    {:noreply, assign(socket, page: 0, search: nil, notebooks: notebooks)}
  end

  defp run_action(%{"repo" => repo, "author" => author}, :repo, socket) do
    socket = assign(socket, author: author, repo: repo, package: nil)
    notebooks = get_notebooks(socket, :repo, 0, [])
    {:noreply, assign(socket, page: 0, search: nil, notebooks: notebooks)}
  end

  defp run_action(%{"author" => author}, :author, socket) do
    # Render 404 if author does not exist
    Accounts.get_by_username!(author)
    socket = assign(socket, author: author, repo: nil, package: nil)
    notebooks = get_notebooks(socket, :author, 0, [])
    {:noreply, assign(socket, page: 0, search: nil, notebooks: notebooks)}
  end

  defp run_action(%{"q" => search}, :search, socket) do
    # We get_notebooks/3 needs :search and :notebooks in the socket
    socket = assign(socket, search: search, notebooks: [])
    notebooks = get_notebooks(socket, :search, 0, [])

    {:noreply,
     assign(socket,
       page: 0,
       search: search,
       notebooks: notebooks,
       author: nil,
       repo: nil,
       package: nil
     )}
  end

  defp run_action(_, :search, socket) do
    socket = assign(socket, search: nil, notebooks: [])
    notebooks = get_notebooks(socket, :search, 0, [])

    {:noreply,
     assign(socket,
       page: 0,
       search: nil,
       notebooks: notebooks,
       author: nil,
       repo: nil,
       package: nil
     )}
  end

  defp run_action(_params, :home, socket) do
    notebooks = get_notebooks(socket, :home, 0, [])

    {:noreply,
     assign(socket,
       page: 0,
       notebooks: notebooks,
       search: nil,
       author: nil,
       repo: nil,
       package: nil
     )}
  end

  defp run_action(_params, :random, socket) do
    notebooks = get_notebooks(socket, :random, 0, [])

    {:noreply,
     assign(socket,
       page: 0,
       notebooks: notebooks,
       search: nil,
       author: nil,
       repo: nil,
       package: nil
     )}
  end

  defp run_action(_params, :top, socket) do
    notebooks = get_notebooks(socket, :top, 0, [])

    {:noreply,
     assign(socket,
       page: 0,
       notebooks: notebooks,
       search: nil,
       author: nil,
       repo: nil,
       package: nil
     )}
  end

  def handle_event("search", %{"value" => ""}, socket) do
    {:noreply, push_patch(socket, to: ~p"/")}
  end

  def handle_event("search", params, socket) do
    timestamp = params["timestamp"]

    cond do
      timestamp && timestamp > socket.assigns.last_search_time ->
        socket =
          socket
          |> assign(timestamp: timestamp)
          |> push_patch(to: ~p"/search?q=#{params["value"]}")

        {:noreply, socket}

      timestamp ->
        {:noreply, socket}

      true ->
        # In LiveView tests we do NOT run js so timestamp=nil
        socket = push_patch(socket, to: ~p"/search?q=#{params["value"]}")

        {:noreply, socket}
    end
  end

  def handle_event("random", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/random")}
  end

  def handle_event("top", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/top")}
  end

  def handle_event("home", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/")}
  end

  def handle_event("load-more", _, socket) do
    %{assigns: %{page: page, notebooks: notebooks, live_action: live_action}} = socket

    next_page = page + 1
    exclude_ids = Enum.map(notebooks, & &1.id)

    {:noreply,
     assign(
       socket,
       notebooks: notebooks ++ get_notebooks(socket, live_action, next_page, exclude_ids),
       page: next_page
     )}
  end

  defp get_notebooks(_socket, :home, page, exclude_ids) do
    Notebooks.list_notebooks(
      per_page: @per_page,
      page: page,
      order: :desc,
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages]
    )
  end

  defp get_notebooks(_socket, :random, page, exclude_ids) do
    Notebooks.list_notebooks(
      per_page: @per_page,
      page: page,
      order: :random,
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages]
    )
  end

  defp get_notebooks(_socket, :top, page, exclude_ids) do
    Notebooks.list_notebooks(
      per_page: @per_page,
      page: page,
      order: :clap_count,
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages]
    )
  end

  defp get_notebooks(%{assigns: %{repo: repo, author: author}}, :repo, page, exclude_ids) do
    Notebooks.list_notebooks(
      github_repo_name: repo,
      github_owner_login: author,
      per_page: @per_page,
      page: page,
      order: :desc,
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages]
    )
  end

  defp get_notebooks(%{assigns: %{author: author}}, :author, page, exclude_ids) do
    Notebooks.list_notebooks(
      github_owner_login: author,
      per_page: @per_page,
      page: page,
      order: :desc,
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages]
    )
  end

  defp get_notebooks(%{assigns: %{package: package}}, :package, page, exclude_ids) do
    Notebooks.list_notebooks(
      package_name: package,
      per_page: @per_page,
      page: page,
      order: :desc,
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages]
    )
  end

  defp get_notebooks(%{assigns: %{search: search}}, :search, page, exclude_ids) do
    per_page = trunc(@per_page / 2)

    searchable_matches =
      Notebooks.list_notebooks(
        searchable: search,
        per_page: per_page,
        page: page,
        order: :desc,
        exclude_ids: exclude_ids,
        require_content: true,
        select_content: true,
        preload: [:user, :repo, :packages]
      )

    exclude_ids = exclude_ids ++ Enum.map(searchable_matches, & &1.id)

    content_matches =
      Notebooks.list_notebooks(
        content: search,
        per_page: per_page,
        page: page,
        order: :desc,
        exclude_ids: exclude_ids,
        require_content: true,
        select_content: true,
        preload: [:user, :repo, :packages]
      )

    searchable_matches ++ content_matches
  end
end
