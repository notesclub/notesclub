defmodule Notesclub.GithubAPI do
  @moduledoc """
  Fetches new notebooks from Github Search API and user data from Github Rest API
  """

  alias Notesclub.GithubAPI

  require Logger

  # Fetch -> GitHubAPI
  # Replace Option with option() typespec/keyword list
  # Fetch struct -> GitHubAPI

  @type options ::
          [per_page: number, page: number, order: binary]
          | [username: binary, per_page: number, page: number, order: binary]
  defstruct notebooks_data: nil,
            total_count: 0,
            response: nil,
            url: nil,
            errors: %{}

  @type t :: %__MODULE__{
          notebooks_data: [any()] | nil,
          total_count: non_neg_integer(),
          response: Req.Response.t(),
          url: String.t(),
          errors: map()
        }

  @doc """

  Gets files with 'livemd' extension from GithubAPI.

  ## Example
  iex> Notesclub.GithubAPI.get([per_page: 10, page: 1, order: "asc"])
  {:ok,
   %GithubAPI{
     notebooks_data: [
       %{
         github_filename: item["name"],
         github_owner_login: owner["login"],
         github_owner_avatar_url: owner["avatar_url"],
         github_repo_name: repo["name"],
         github_repo_full_name: repo["full_name"],
         github_repo_fork: repo["fork"],
         github_html_url: item["html_url"]
       },
       ...
     ],
     ...
   }}
  ]"}

  iex> Notesclub.GithubAPI.get(:wrong_arguments)
  {:error, %GithubAPI{response: response}}

  Arguments:
  - order can be "asc" or "desc"
  - per_page could be up to 100 according to GithubAPI's documentation.
    Yet, a value greather than 10 often returns response from a wrong page.

  Other considerations:
  A common error happens when we reach GithubAPI's rate limit.
  The first .livemd file should be structs.livemd — at least on 2022-08-15.
  """
  @spec get(options()) :: {:ok, GithubAPI.t()} | {:error, GithubAPI.t()}
  def get(options) do
    options
    |> build_url()
    |> make_request()
    |> extract_notebooks_data()
  end

  @doc """

  Using a given username, look up the corresponding user record from Github API

  ## Example
  iex> Notesclub.GithubAPI.get_user_info("octocat")
  {:ok, %{twitter_username: "twitter_octo", name: "octo realname"}

  iex> Notesclub.GithubAPI.get_user_info(-1)
  {:error, :not_found}

  Arguments:
  - username can be a string or a positive integer
  """
  @spec get_user_info(String.t()) :: {:ok, map()} | {:error, atom()}
  def get_user_info(username) do
    username
    |> build_url()
    |> make_request()
    |> extract_user_info()
  end

  defp extract_notebooks_data(%GithubAPI{response: response} = fetch) do
    prepare_data(fetch, response.body["items"])
  end

  defp extract_user_info(%GithubAPI{response: response}) do
    with 200 <- response.status do
      user_info = %{
        twitter_username: response.body["twitter_username"],
        name: response.body["name"]
      }

      {:ok, user_info}
    else
      404 -> {:error, :not_found}
      _ -> {:error, :uncaught_error}
    end
  end

  defp prepare_data(%GithubAPI{response: response} = fetch, nil) do
    Logger.error("GithubAPI.Search, response: " <> inspect(response))
    {:error, fetch}
  end

  defp prepare_data(%GithubAPI{response: response} = fetch, items) do
    notebooks_data =
      items
      # This filter shouldn't be needed. See function for more info.
      |> filter_private_repos(response)
      |> Enum.map(fn item ->
        repo = item["repository"]
        owner = repo["owner"]

        %{
          github_filename: item["name"],
          github_owner_login: owner["login"],
          github_owner_avatar_url: owner["avatar_url"],
          github_repo_name: repo["name"],
          github_repo_full_name: repo["full_name"],
          github_repo_fork: repo["fork"],
          github_html_url: item["html_url"]
        }
      end)

    fetch =
      fetch
      |> Map.put(:notebooks_data, notebooks_data)
      |> Map.put(:total_count, response.body["total_count"])

    {:ok, fetch}
  end

  #  We make sure we only store public repos/files
  #  Yet, our credentials should only be able to access public repos
  # so this function shouldn't be needed
  defp filter_private_repos(items, response) do
    Enum.filter(items, fn i ->
      case i["repository"]["private"] do
        false ->
          i

        _ ->
          Logger.error(
            "GithubAPI.Search fetched a private repo.\nRepo:\n" <>
              inspect(i) <> "\nFull GithubAPI's response:\n" <> inspect(response)
          )

          false
      end
    end)
  end

  defp build_url(username: username, per_page: per_page, page: page, order: order) do
    %GithubAPI{
      url:
        "https://api.github.com/search/code?q=user:#{username}+extension:livemd&per_page=#{per_page}&page=#{page}&sort=indexed&order=#{order}"
    }
  end

  defp build_url(per_page: per_page, page: page, order: order) do
    %GithubAPI{
      url:
        "https://api.github.com/search/code?q=extension:livemd&per_page=#{per_page}&page=#{page}&sort=indexed&order=#{order}"
    }
  end

  defp build_url(username) do
    %GithubAPI{
      url: "https://api.github.com/users/#{username}"
    }
  end

  defp make_request(%GithubAPI{} = fetch) do
    github_api_key = Application.get_env(:notesclub, :github_api_key)

    response =
      Req.get!(
        fetch.url,
        headers: [
          Accept: ["application/vnd.github+json"],
          Authorization: ["token #{github_api_key}"]
        ]
      )

    Map.put(fetch, :response, response)
  end
end
