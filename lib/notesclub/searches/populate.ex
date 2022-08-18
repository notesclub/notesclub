defmodule Notesclub.Searches.Populate do
  require Logger

  alias Notesclub.Notebooks
  alias Notesclub.Searches
  alias Notesclub.Searches.Search
  alias Notesclub.Searches.Fetch
  alias Notesclub.Searches.Fetch.Options

  @doc """
  Fetches notebooks from Github and saves one Search and creates n Notebook records.

  ## Example
  iex> populate(per_page: 5, page: 1, order: "asc")
  %{created: 3, updated: 2, errors: 0}

  # TODO: We should probably only save the Search record and NOT the Notebooks.
          Then, enqueue a job to download all livemd within the repo's default branch
          Also, we would download the history of blobs of each file.
          That way, we could update notebooks instead of creating new ones.
          Useful to send emails, tweets, etc. with new notebooks.
  """
  def populate(%Options{per_page: per_page, page: page, order: order} = options) do
    case Fetch.get(options) do
      {:ok, %Fetch{notebooks_data: notebooks_data, response: response, url: url}} ->
        headers = Enum.into(response.headers, %{}) # response.headers is a list of tuples and we store a map (jsonb)
        case Searches.create_search(%{response_notebooks_count: length(notebooks_data), response_body: response.body, response_headers: headers, response_private: response.private, response_status: response.status, url: url, order: order, page: page, per_page: per_page}) do
          {:ok, search} ->
            if search.response_notebooks_count == per_page do
              save_notebooks(notebooks_data, search)
            end
          {:error, changeset} ->
            Logger.error "Searches.Populate ERROR populate while saving search\nChangeset:" <> inspect(changeset.errors) <> "\nOptions:\n" <> inspect(options)
            num = length(notebooks_data)
            %{created: 0, updated: 0, errors: num, downloaded: num, error: "ERROR downloading data"}
        end
      {:error, %Fetch{} = fetch} ->
        Logger.error "Searches.Populate ERROR before saving search"
        %{created: 0, updated: 0, errors: 0, downloaded: 0, error: "ERROR downloading data"}
    end
  end

  def next() do
    Logger.info "Populate.next() start. Downloading new notebooks."

    result =
      Searches.get_last_search()
      |> next_options()
      |> populate()

    Logger.info "Populate.next() end" <> inspect(result)
  end

  defp next_options(nil), do: %Options{per_page: 5, page: 1, order: "asc"}
  defp next_options(%Search{} = last_search) do
    %Options{
      per_page: last_search.per_page,
      page: next_page(last_search),
      order: last_search.order
    }
  end

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
end
