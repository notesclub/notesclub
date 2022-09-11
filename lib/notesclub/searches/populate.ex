defmodule Notesclub.Searches.Populate do
  require Logger

  @daily_page_limit 50 # max: 200 when per_page=5. Afterwards Github returns "Only the first 1000 search results are available"
  @default_per_page 5

  def default_per_page(), do: @default_per_page # public function so we can mock it in tests
  def daily_page_limit, do: @daily_page_limit   # public function so we can mock it in tests

  alias Notesclub.Notebooks
  alias Notesclub.Searches
  alias Notesclub.Accounts
  alias Notesclub.Repos
  alias Notesclub.Searches.Search
  alias Notesclub.Searches.Fetch
  alias Notesclub.Searches.Fetch.Options

  @doc """
  Makes a request to fetch new notebooks from Github
  per_page, page and order depends on the last search

  When cron uses next(), every day we fetch the last @daily_page_limit indexed by GitHub
  """
  def next() do
    Logger.info "Populate.next() start. Downloading new notebooks."

    last_search_from_today = Searches.get_last_search_from_today()
    daily_page_limit = __MODULE__.daily_page_limit()
    cond do
      last_search_from_today && (last_search_from_today.page >= daily_page_limit) ->
        Logger.info "Populate.next() end — reached #{daily_page_limit} daily pages. Do NOT fetch Github anymore for today"
        %{created: 0, updated: 0, downloaded: 0}
      true ->
        last_search_from_today
        |> next_options()
        |> populate()
        |> log_info("Populate.next() end")
    end
  end

  @doc """
  Makes a request to fetch new notebooks from Github
  per_page, page and order depends on the last search

  When cron uses next_loop(), every day we fetch the last @daily_page_limit indexed by GitHub
  """
  def next_loop() do
    Logger.info "Populate.next_loop() start. Downloading new notebooks."

    Searches.get_last_search_from_today()
    |> next_options()
    |> populate()
    |> log_info("Populate.next_loop() end")
  end

  defp populate(%Options{per_page: per_page, page: page, order: order} = options) do
    case Fetch.get(options) do
      {:ok, %Fetch{notebooks_data: notebooks_data, response: response, url: url}} ->
        case Searches.create_search(%{response_notebooks_count: length(notebooks_data), response_status: response.status, url: url, order: order, page: page, per_page: per_page}) do
          {:ok, search} ->
            if search.response_notebooks_count == per_page do
              save_notebooks(notebooks_data, search)
            end
          {:error, changeset} ->
            Logger.error "Searches.Populate ERROR populate while saving search\nChangeset:" <> inspect(changeset.errors) <> "\nOptions:\n" <> inspect(options)
            num = length(notebooks_data)
            %{created: 0, updated: 0, errors: num, downloaded: num, error: "ERROR downloading data"}
        end
      {:error, %Fetch{errors: errors}} ->
        Logger.warn "Searches.Populate ERROR before saving search: " <> inspect(errors)
        %{created: 0, updated: 0, errors: 0, downloaded: 0, error: "ERROR downloading data: " <> inspect(errors)}
    end
  end

  defp log_info(result, text) do
    Logger.info text <> inspect(result)
    result
  end

  defp next_options(nil), do: %Options{per_page: __MODULE__.default_per_page(), page: 1, order: "desc"}
  defp next_options(%Search{} = last_search) do
    %Options{
      per_page: last_search.per_page,
      page: next_page(last_search),
      order: last_search.order
    }
  end

  # Github only returns the last 1000 records indexed, So when per_page=5, the page 201 returns error
  defp next_page(%Search{page: 200, per_page: 5, response_notebooks_count: 5}), do: 1
  # We repeat the page when last search per_page doesn't match the returned data
  # When this happens, sometimes the returned results are not from the page
  # This happens especially for per_page > 5
  defp next_page(%Search{per_page: same, response_notebooks_count: same} = last_search), do: last_search.page + 1
  defp next_page(%Search{} = last_search), do: last_search.page

  defp save_notebooks(notebooks_data, %Search{} = search) when is_list(notebooks_data) do
    notebooks_data
    |> Enum.map(fn new_attributes ->
      new_attributes
      |> Map.put(:search_id, search.id)
      |> get_or_create_user()
      |> get_or_create_repo()
      |> create_or_update_notebook()
    end)
    |> Enum.frequencies()
    |> Map.put(:downloaded, length(notebooks_data))
    |> Map.delete(:error)
    |> Enum.into(%{created: 0, updated: 0}) # In case they don't exist
  end

  defp create_or_update_notebook(new_attributes) do
    existent_notebook = Notebooks.get_by_filename_owner_and_repo(new_attributes.github_filename, new_attributes.github_owner_login, new_attributes.github_repo_name)
    if existent_notebook do
      case Notebooks.update_notebook(existent_notebook, new_attributes) do
        {:ok, notebook} ->
          Logger.info "Searches.Populate Notebook UPDATED. id: #{notebook.id}, filename: #{notebook.github_filename}"
          :updated
        {:error, changeset} ->
          Logger.error "Searches.Populate ERROR create_or_update_notebook while UPDATING: " <> inspect(changeset.errors)
          :error
      end
    else
      case Notebooks.create_notebook(new_attributes) do
        {:ok, notebook} ->
          Logger.info "Searches.Populate Notebook CREATED. id: #{notebook.id}, filename: #{notebook.github_filename}"
          :created
        {:error, changeset} ->
          Logger.error "Searches.Populate ERROR create_or_update_notebook while CREATING: " <> inspect(changeset.errors)
          :error
      end
    end
  end

  defp get_or_create_user(attrs) do
    case Accounts.get_by_name(attrs.github_owner_login) do
      nil ->
        case Accounts.create_user(%{name: attrs.github_owner_login}) do
          {:ok, user} ->
            Map.put_new(attrs, :user_id, user.id)
          {:error, error} ->
            Logger.info("Error while creating user by name #{attrs.github_owner_login} details #{inspect error}")
            attrs
        end
      user -> Map.put_new(attrs, :user_id, user.id)
    end
  end

  defp get_or_create_repo(attrs) do
    case Repos.get_by_name_and_user_id(%{name: attrs.github_repo_name, user_id: attrs.user_id}) do
      nil ->
        case Repos.create_repo(%{name: attrs.github_repo_name, user_id: attrs.user_id}) do
          {:ok, repo} -> Map.put_new(attrs, :repo_id, repo.id)
          {:error, error} ->
            Logger.info("Error while creating repo by repo name #{attrs.github_repo_name} with user #{attrs.user_id} details #{inspect error}")
            attrs
        end
      repo -> Map.put_new(attrs, :repo_id, repo.id)
    end
  end
end
