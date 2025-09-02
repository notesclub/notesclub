defmodule NotesclubWeb.NotebookLive.Index do
  use NotesclubWeb, :live_view
  use PhoenixHTMLHelpers
  import Phoenix.Component
  import Phoenix.LiveView

  alias Notesclub.Accounts
  alias Notesclub.Notebooks

  @per_page 20

  def per_page, do: @per_page

  def mount(_params, _session, socket) do
    {:ok, assign(socket, last_search_time: 0, notebooks_count: Notebooks.count(), sort: :new)}
  end

  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    run_action(params, live_action, socket)
  end

  defp run_action(%{"package" => package} = params, :package, socket) do
    sort = extract_sort(params)
    socket = assign(socket, package: package, tag: nil, author: nil, repo: nil, sort: sort)
    notebooks = get_notebooks(socket, :package, 0, [])
    {:noreply, assign(socket, page: 0, search: nil, notebooks: notebooks, action: :package)}
  end

  defp run_action(%{"tag" => tag} = params, :tag, socket) do
    sort = extract_sort(params)
    socket = assign(socket, tag: tag, author: nil, repo: nil, package: nil, sort: sort)
    notebooks = get_notebooks(socket, :tag, 0, [])
    {:noreply, assign(socket, page: 0, search: nil, notebooks: notebooks, action: :tag)}
  end

  defp run_action(%{"repo" => repo, "author" => author} = params, :repo, socket) do
    sort = extract_sort(params)
    socket = assign(socket, author: author, repo: repo, package: nil, tag: nil, sort: sort)
    notebooks = get_notebooks(socket, :repo, 0, [])
    {:noreply, assign(socket, page: 0, search: nil, notebooks: notebooks, action: :repo)}
  end

  defp run_action(%{"author" => username} = params, :author, socket) do
    # Render 404 if author does not exist
    Accounts.get_by_username!(username)
    sort = extract_sort(params)
    socket = assign(socket, author: username, repo: nil, package: nil, tag: nil, sort: sort)
    notebooks = get_notebooks(socket, :author, 0, [])
    {:noreply, assign(socket, page: 0, search: nil, notebooks: notebooks, action: :author)}
  end

  defp run_action(%{"username" => username}, :stars, socket) do
    # Render 404 if author does not exist
    user = Accounts.get_by_username!(username)
    socket = assign(socket, user: user)
    notebooks = get_notebooks(socket, :starred, 0, [])

    {:noreply,
     assign(socket,
       page: 0,
       search: nil,
       notebooks: notebooks,
       action: :starred,
       author: username,
       repo: nil,
       package: nil,
       tag: nil
     )}
  end

  defp run_action(%{"q" => search} = params, :search, socket) do
    # We get_notebooks/3 needs :search and :notebooks in the socket
    sort = extract_sort(params)
    socket = assign(socket, search: search, notebooks: [], sort: sort)
    notebooks = get_notebooks(socket, :search, 0, [])

    {:noreply,
     assign(socket,
       page: 0,
       search: search,
       notebooks: notebooks,
       author: nil,
       repo: nil,
       package: nil,
       tag: nil,
       action: :search
     )}
  end

  defp run_action(params, :search, socket) do
    sort = extract_sort(params)
    socket = assign(socket, search: nil, notebooks: [], sort: sort)
    notebooks = get_notebooks(socket, :search, 0, [])

    {:noreply,
     assign(socket,
       page: 0,
       search: nil,
       notebooks: notebooks,
       author: nil,
       repo: nil,
       package: nil,
       tag: nil,
       action: :search
     )}
  end

  defp run_action(params, :home, socket) do
    sort = extract_sort(params)
    socket = assign(socket, sort: sort)
    notebooks = get_notebooks(socket, :home, 0, [])

    {:noreply,
     assign(socket,
       page: 0,
       notebooks: notebooks,
       search: nil,
       author: nil,
       repo: nil,
       package: nil,
       tag: nil,
       action: :home
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
       package: nil,
       tag: nil,
       action: :random
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
       package: nil,
       tag: nil,
       action: :top
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
          |> push_patch(
            to:
              path_for_action(
                :search,
                %{search: params["value"]},
                socket.assigns[:sort] || :new
              )
          )

        {:noreply, socket}

      timestamp ->
        {:noreply, socket}

      true ->
        # In LiveView tests we do NOT run js so timestamp=nil
        socket =
          push_patch(
            socket,
            to:
              path_for_action(:search, %{search: params["value"]}, socket.assigns[:sort] || :new)
          )

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

  def handle_event(
        "set-sort",
        %{"sort" => sort_str},
        %{assigns: %{live_action: live_action}} = socket
      ) do
    sort =
      case sort_str do
        "new" -> :new
        "top" -> :top
        "random" -> :random
        _ -> :new
      end

    {:noreply, push_patch(socket, to: path_for_action(live_action, socket.assigns, sort))}
  end

  def handle_event("toggle-sort", _, %{assigns: %{live_action: live_action}} = socket) do
    current_sort = socket.assigns[:sort] || :new

    new_sort =
      case current_sort do
        :new -> :top
        :top -> :random
        _ -> :new
      end

    {:noreply, push_patch(socket, to: path_for_action(live_action, socket.assigns, new_sort))}
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

  defp get_notebooks(%{assigns: %{sort: sort}}, :home, page, exclude_ids) do
    Notebooks.list_notebooks(
      per_page: @per_page,
      page: page,
      order: order_for(sort),
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages, :tags]
    )
  end

  defp get_notebooks(_socket, :random, page, exclude_ids) do
    Notebooks.list_notebooks(
      per_page: @per_page,
      page: page,
      order: :random,
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages, :tags]
    )
  end

  defp get_notebooks(_socket, :top, page, exclude_ids) do
    Notebooks.list_notebooks(
      per_page: @per_page,
      page: page,
      order: :ai_rating,
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages, :tags]
    )
  end

  defp get_notebooks(
         %{assigns: %{repo: repo, author: author, sort: sort}},
         :repo,
         page,
         exclude_ids
       ) do
    Notebooks.list_notebooks(
      github_repo_name: repo,
      github_owner_login: author,
      per_page: @per_page,
      page: page,
      order: order_for(sort),
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages, :tags]
    )
  end

  defp get_notebooks(%{assigns: %{author: author, sort: sort}}, :author, page, exclude_ids) do
    Notebooks.list_notebooks(
      github_owner_login: author,
      per_page: @per_page,
      page: page,
      order: order_for(sort),
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages, :tags]
    )
  end

  defp get_notebooks(%{assigns: %{user: user}}, :starred, page, exclude_ids) do
    Notebooks.list_starred_notebooks_by_user(
      user,
      page: page,
      per_page: @per_page,
      exclude_ids: exclude_ids,
      order: :desc,
      require_content: true,
      preload: [:user, :repo, :packages, :tags]
    )
  end

  defp get_notebooks(%{assigns: %{package: package, sort: sort}}, :package, page, exclude_ids) do
    Notebooks.list_notebooks(
      package_name: package,
      per_page: @per_page,
      page: page,
      order: order_for(sort),
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages, :tags]
    )
  end

  defp get_notebooks(%{assigns: %{tag: tag, sort: sort}}, :tag, page, exclude_ids) do
    Notebooks.list_notebooks(
      tag_name: tag,
      per_page: @per_page,
      page: page,
      order: order_for(sort),
      exclude_ids: exclude_ids,
      require_content: true,
      preload: [:user, :repo, :packages, :tags]
    )
  end

  defp get_notebooks(%{assigns: %{search: search, sort: sort}}, :search, page, exclude_ids) do
    # Check if search is wrapped in quotes for exact search
    if search && String.starts_with?(search, "\"") && String.ends_with?(search, "\"") do
      # Exact search - remove quotes and use existing logic
      exact_search = String.slice(search, 1..(String.length(search) - 2))
      per_page = trunc(@per_page / 2)

      searchable_matches =
        Notebooks.list_notebooks(
          searchable: exact_search,
          per_page: per_page,
          page: page,
          order: order_for(sort),
          exclude_ids: exclude_ids,
          require_content: true,
          select_content: true,
          preload: [:user, :repo, :packages, :tags]
        )

      exclude_ids = exclude_ids ++ Enum.map(searchable_matches, & &1.id)

      content_matches =
        Notebooks.list_notebooks(
          content: exact_search,
          per_page: per_page,
          page: page,
          order: order_for(sort),
          exclude_ids: exclude_ids,
          require_content: true,
          select_content: true,
          preload: [:user, :repo, :packages, :tags]
        )

      searchable_matches ++ content_matches
    else
      # Full-text search
      Notebooks.list_notebooks(
        full_text_search: search,
        per_page: @per_page,
        page: page,
        order: order_for_search(sort),
        exclude_ids: exclude_ids,
        require_content: true,
        select_content: true,
        preload: [:user, :repo, :packages, :tags]
      )
    end
  end

  defp extract_sort(%{"sort" => sort}) when sort in ["new", "top", "random"],
    do: String.to_existing_atom(sort)

  defp extract_sort(_), do: :new

  defp order_for(:top), do: :ai_rating
  defp order_for(:random), do: :random
  defp order_for(_), do: :desc

  defp order_for_search(:top), do: :ai_rating
  defp order_for_search(:new), do: :desc
  defp order_for_search(:random), do: :random
  defp order_for_search(_), do: :relevance

  defp path_for_action(:home, _assigns, sort), do: "/" <> sort_query(sort)

  defp path_for_action(:author, %{author: author}, sort) when is_binary(author),
    do: "/#{author}" <> sort_query(sort)

  defp path_for_action(:package, %{package: package}, sort) when is_binary(package),
    do: "/hex/#{package}" <> sort_query(sort)

  defp path_for_action(:tag, %{tag: tag}, sort) when is_binary(tag),
    do: "/tags/#{tag}" <> sort_query(sort)

  defp path_for_action(:repo, %{author: author, repo: repo}, sort)
       when is_binary(author) and is_binary(repo),
       do: "/#{author}/#{repo}" <> sort_query(sort)

  defp path_for_action(:search, %{search: search}, sort) do
    base = "/search?q=" <> URI.encode_www_form(search || "")

    case sort do
      :new -> base
      other -> base <> "&sort=" <> Atom.to_string(other)
    end
  end

  defp path_for_action(other, _assigns, _sort) when other in [:random, :top, :starred], do: "/"

  defp sort_query(:new), do: ""
  defp sort_query(:top), do: "?sort=top"
  defp sort_query(:random), do: "?sort=random"
end
