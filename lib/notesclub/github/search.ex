defmodule Notesclub.Github.Search do
  @github_api_key System.get_env("NOTES_CLUB_GITHUB_API_KEY")

  alias Notesclub.Notebooks.Notebook

  require Logger

  @spec get(per_page: number, page: number, order: atom) :: list | {:error, Req.Response.t()}
  @doc """
  Fetches files with 'livemd' extension on GitHub.

  Example:
  Notesclub.Github.Search.get(per_page: 10, page: 1, order: :asc)

  Returns one of these:
  {:ok, [%Notebook{...}, %Notebook{...}...}
  {:error, error}

  Arguments:
  - atom can be :asc or :desc
  - per_page could be up to 100 according to GitHub's documentation.
    Yet, a value greather than 10 often returns response from a wrong page.

  Other considerations:
  A common error happens when we reach Github's rate limit.
  The first .livemd file should be structs.livemd — at least on 2022-08-15.
  """
  def get([per_page: _, page: _, order: _] = options) do
    response = make_request(options)
    prepare_data(response, response.body["items"])
  end

  defp prepare_data(response, nil) do
    Logger.error "Github.Search, response: " <> inspect(response)
    {:error, response}
  end
  defp prepare_data(response, items) do
    Logger.info "Github.Search, response: " <> inspect(response)

    items
    |> filter_private_repos(response) # This filter shouldn't be needed. See function for more info.
    |> Enum.map(fn i ->
      repo = i["repository"]
      owner = repo["owner"]

      %Notebook{
        github_filename: i["name"],
        github_owner_login: owner["login"],
        github_repo_name: repo["name"],
        github_html_url: i["html_url"],
        github_owner_avatar_url: owner["avatar_url"]
      }
      end)
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
          Logger.error "Github.Search fetched a private repo.\nRepo:\n" <> inspect(i) <> "\nFull GitHub's response:\n" <> inspect(response)
          false
      end
    end)
  end

  defp make_request(per_page: per_page, page: page, order: order) do
    Req.get!(
      "https://api.github.com/search/code?q=extension:livemd&per_page=#{per_page}&page=#{page}&sort=indexed&order=#{order}",
      headers: [
        Accept: ["application/vnd.github+json"],
        Authorization: ["token #{@github_api_key}"]
      ]
    )
  end
end
