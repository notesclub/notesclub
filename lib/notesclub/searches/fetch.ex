defmodule Notesclub.Searches.Fetch do
  alias Notesclub.Searches.Fetch
  alias Notesclub.Searches.Fetch.Options

  require Logger

  defstruct options: Options, url: nil, response: nil, notebooks_data: nil

  @doc """

  Gets files with 'livemd' extension from Fetch.

  ## Example
  iex> Notesclub.Searches.Fetch.get(%Options{per_page: 10, page: 1, order: "asc"})
  {:ok, %Fetch{notebooks_data: [%Notebook{...}, %Notebook{...}]}"}

  iex> Notesclub.Searches.Fetch.get(:wrong_arguments)
  {:error, %Fetch{response: response}}

  Arguments:
  - order can be "asc" or "desc"
  - per_page could be up to 100 according to Fetch's documentation.
    Yet, a value greather than 10 often returns response from a wrong page.

  Other considerations:
  A common error happens when we reach Fetch's rate limit.
  The first .livemd file should be structs.livemd — at least on 2022-08-15.
  """
  def get(%Options{} = options) do
    github_api_key = get_github_api_key()
    if github_api_key != nil || Mix.env() == :test do
      options
      |> build_url()
      |> make_request(github_api_key)
      |> extract_notebooks_data()
    else
      Logger.error "No env variable Github API key"
      {:error, %Fetch{}}
    end
  end

  defp extract_notebooks_data(%Fetch{response: response} = fetch) do
    prepare_data(fetch, response.body["items"])
  end

  defp prepare_data(%Fetch{response: response} = fetch, nil) do
    Logger.error "Fetch.Search, response: " <> inspect(response)
    {:error, fetch}
  end
  defp prepare_data(%Fetch{response: response} = fetch, items) do
    Logger.info "Fetch.Search, response: " <> inspect(response)

    notebooks_data =
      items
      |> filter_private_repos(response) # This filter shouldn't be needed. See function for more info.
      |> Enum.map(fn item ->
        repo = item["repository"]
        owner = repo["owner"]

        %{
          github_filename: item["name"],
          github_owner_login: owner["login"],
          github_repo_name: repo["name"],
          github_html_url: item["html_url"],
          github_owner_avatar_url: owner["avatar_url"],
          github_api_response: item
        }
        end)

    {:ok, Map.put(fetch, :notebooks_data, notebooks_data)}
  end

  # We make sure we only store public repos/files
  # Yet, our credentials should only be able to access public repos
  # so this function shouldn't be needed
  defp filter_private_repos(items, response) do
    Enum.filter(items, fn i ->
      case i["repository"]["private"] do
        false ->
          i
        _ ->
          Logger.error "Fetch.Search fetched a private repo.\nRepo:\n" <> inspect(i) <> "\nFull Fetch's response:\n" <> inspect(response)
          false
      end
    end)
  end

  defp build_url(%Options{per_page: per_page, page: page, order: order} = options) do
    %Fetch{
      url: "https://api.github.com/search/code?q=extension:livemd&per_page=#{per_page}&page=#{page}&sort=indexed&order=#{order}",
      options: options
    }
  end

  defp make_request(%Fetch{} = fetch, github_api_key) do
    response = Req.get!(fetch.url,
      headers: [
        Accept: ["application/vnd.github+json"],
        Authorization: ["token #{github_api_key}"]
      ]
    )
    Map.put(fetch, :response, response)
  end

  defp get_github_api_key(), do: Application.get_env(:notesclub, :github_api_key)
end
