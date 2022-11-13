defmodule NotesclubWeb.NotesLive do
  use NotesclubWeb, :live_view
  use Phoenix.HTML
  import Phoenix.LiveView.Helpers
  import Phoenix.LiveView

  alias NotesclubWeb.NotesLive
  alias Notesclub.Notebooks

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

  def handle_params(params, url, socket) do
    case connected?(socket) do
      true ->
        handle_params_internal(params, url, socket)

      false ->
        {:noreply, assign(socket, notebooks: [], notebooks_count: 0, search: nil, page: :random)}
    end
  end

  defp handle_params_internal(%{"author" => author, "repo" => repo}, _url, socket) do
    notebooks = Notebooks.list_repo_author_notebooks_desc(repo, author)
    count = Notebooks.count()

    {:noreply,
     assign(socket, notebooks: notebooks, notebooks_count: count, search: nil, page: :repo)}
  end

  defp handle_params_internal(%{"author" => author}, _url, socket) do
    notebooks = Notebooks.list_author_notebooks_desc(author)
    count = Notebooks.count()

    {:noreply,
     assign(socket, notebooks: notebooks, notebooks_count: count, search: nil, page: :author)}
  end

  defp handle_params_internal(%{"search" => "content:" <> term}, _url, socket) do
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

  defp handle_params_internal(%{"search" => term}, _url, socket) do
    notebooks = Notebooks.list_notebooks(github_filename: term)
    count = Notebooks.count()

    {:noreply,
     assign(socket, notebooks: notebooks, notebooks_count: count, search: term, page: :all)}
  end

  defp handle_params_internal(%{}, url, socket) do
    cond do
      String.ends_with?(url, "/last_week") ->
        notebooks = Notebooks.list_notebooks_since(7)
        count = Notebooks.count()

        {:noreply,
         assign(socket,
           notebooks: notebooks,
           notebooks_count: count,
           search: nil,
           page: :last_week
         )}

      String.ends_with?(url, "/last_month") ->
        notebooks = Notebooks.list_notebooks_since(30)
        count = Notebooks.count()

        {:noreply,
         assign(socket,
           notebooks: notebooks,
           notebooks_count: count,
           search: nil,
           page: :last_month
         )}

      String.ends_with?(url, "/all") ->
        notebooks = Notebooks.list_notebooks()
        count = Notebooks.count()

        {:noreply,
         assign(socket, notebooks: notebooks, notebooks_count: count, search: nil, page: :all)}

      true ->
        notebooks = Notebooks.list_random_notebooks(%{limit: @notebooks_in_home_count})
        count = Notebooks.count()

        {:noreply,
         assign(socket, notebooks: notebooks, notebooks_count: count, search: nil, page: :random)}
    end
  end

  def render(assigns) do
    ~H"""
    <section class="relative min-h-screen bg-split-gray">
      <header class="pt-2 pl-4 text-gray-500 sm:text-xl md:text-2xl">
        <%= link "Notesclub", to: "/" %>
      </header>
      <h1 class="text-4xl text-center mt-16 font-bold text-gray-900 sm:text-5xl md:text-6xl">Discover <span class="text-indigo-600">Livebook</span> notebooks</h1>
      <p class="mt-3 text-gray-500 sm:text-lg md:mt-5 md:text-xl text-center">
        Updated every day.
        <%= link("Contribute on Github", to: "https://github.com/notesclub/notesclub", class: "text-blue-600", target: "_blank") %> and join the <%= link "conversation in the elixir forum", to: "https://elixirforum.com/t/notesclub-discover-livebook-notebooks/49698", class: "text-blue-600", target: "_blank" %>.
      </p>
      <form id="search" class="flex justify-center my-12" phx-submit="search">
        <input type="text" name="term" value={@search}
          class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm mr-6">
        <input type="submit" name="Submit"
          class="inline-flex items-center rounded-md border border-transparent bg-indigo-600 px-3 py-2 text-sm font-medium leading-4 text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">
      </form>
      <section class="sm:w-3/4 w-11/12 mx-auto overflow-x-scroll shadow ring-1 ring-black ring-opacity-5 rounded-lg">
        <table class="table-auto divide-y divide-gray-300 w-full mx-auto text-sm">
          <thead class="bg-gray-100 font-semibold text-gray-900">
          <td class="p-4" align="left" scope="col">Author/Repo</td>
          <td align="left" scope="col">
            File
            <%= if assigns[:search] do %>
              / Search
            <% end %>
          </td>
          <td align="left" scope="col">Actions</td>
        </thead>
        <%= for notebook <- @notebooks do %>
          <tbody class="h-20 bg-white">
              <td>
                <article class="flex w-min-max p-4 min-w-max">
                  <%= live_patch to: Routes.notes_path(@socket, :author, notebook.github_owner_login) do %>
                      <%= img_tag notebook.github_owner_avatar_url, class: "h-10 w-10 rounded-full", alt: "avatar" %>
                  <% end %>
                  <div class="flex flex-col ml-4">
                    <%= live_patch "@#{notebook.github_owner_login}",
                      to: Routes.notes_path(@socket, :author, notebook.github_owner_login),
                      class: "font-medium whitespace-nowrap" %>
                    <%= live_patch Notesclub.StringTools.truncate(notebook.github_repo_name, 25),
                      to: Routes.notes_path(@socket, :repo, notebook.github_owner_login, notebook.github_repo_name) %>
                  </div>
                </article>
              </td>
              <td>
                <p>
                  <%= link Notesclub.StringTools.truncate(notebook.github_filename, 50), to: notebook.url || notebook.github_html_url, target: "_blank" %>
                </p>
                <%= if assigns[:search] && !Regex.match?(~r/#{@search}/i, notebook.github_filename)  do %>
                  <p class="text-gray-400">
                    <%= Notesclub.Notebooks.content_fragment(notebook, @search) %>
                  </p>
                <% end %>
              </td>
              <td>
                <%= link "Run in Livebook", to: "https://livebook.dev/run?url=#{notebook.github_html_url}", target: "_blank" %>
              </td>
          </tbody>
        <% end %>
        </table>
      </section>
      <div class="text-center p-6">
          <a phx-click="random" style="cursor:pointer;" class="px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">Random</a>
        <%= unless @page == :last_week do %>
          <%= live_patch "Last week",
            to: Routes.notes_path(@socket, :last_week),
            class: "px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" %>
        <% end %>
        <%= unless @page == :last_month do %>
          <%= live_patch "Last month",
            to: Routes.notes_path(@socket, :last_month),
            class: "px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" %>
        <% end %>
      </div>
      <footer class="p-8 w-full">
        <h2 class="text-center text-gray-400 font-semibold"><%= @notebooks_count %> Livebook Notebooks</h2>
        <h2 class="pt-4 text-center text-gray-400 font-semibold">Founded by <%= link "hec", to: "https://hecperez.com", class: "underline underline-offset-2" %></h2>
      </footer>
    </section>
    """
  end
end