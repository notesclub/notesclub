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
            incomplete_results: false,
            response: nil,
            url: nil,
            errors: %{}

  @type t :: %__MODULE__{
          notebooks_data: [any()] | nil,
          total_count: non_neg_integer(),
          incomplete_results: boolean(),
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
  @spec get_user_info(number() | binary()) :: {:ok, map()} | {:error, atom()}
  def get_user_info(github_id) when is_integer(github_id) do
    %GithubAPI{url: "https://api.github.com/user/#{github_id}"}
    |> make_request()
    |> extract_user_info()
  end

  def get_user_info(username) when is_binary(username) do
    %GithubAPI{url: "https://api.github.com/users/#{username}"}
    |> make_request()
    |> extract_user_info()
  end

  defp extract_notebooks_data(%GithubAPI{response: response} = fetch) do
    prepare_data(fetch, response.body["items"])
  end

  defp extract_user_info(%GithubAPI{response: response}) do
    case response.status do
      200 ->
        user_info = %{
          twitter_username: response.body["twitter_username"],
          name: response.body["name"],
          avatar_url: response.body["avatar_url"],
          github_id: response.body["id"]
        }

        {:ok, user_info}

      404 ->
        {:error, :not_found}

      _ ->
        {:error, :uncaught_error}
    end
  end

  defp prepare_data(fetch, nil), do: {:error, fetch}

  defp prepare_data(%GithubAPI{response: response} = fetch, items) do
    # This filter shouldn't be needed. See function for more info.
    case filter_private_repos(items, response) do
      {:ok, public_items} ->
        fetch =
          fetch
          |> Map.put(:notebooks_data, Enum.map(public_items, &extract_notebook_data/1))
          |> Map.put(:total_count, response.body["total_count"] || 0)
          |> Map.put(:incomplete_results, response.body["incomplete_results"] == true)

        {:ok, fetch}

      {:error, reason} ->
        {:error, Map.put(fetch, :errors, %{filter_private_repos: reason})}
    end
  end

  defp extract_notebook_data(item) do
    repo = item["repository"]
    owner = repo["owner"]

    %{
      github_filename: item["name"],
      github_owner_login: owner["login"],
      github_owner_id: owner["id"],
      github_owner_avatar_url: owner["avatar_url"],
      github_repo_name: repo["name"],
      github_repo_full_name: repo["full_name"],
      github_repo_fork: repo["fork"],
      github_html_url: item["html_url"]
    }
  end

  #  We make sure we only store public repos/files
  #  Yet, our credentials should only be able to access public repos
  # so this function shouldn't be needed
  #
  # If it discards EVERY item, we return an error instead of an empty list:
  # the response is probably not what we expect —e.g. GitHub stopped returning
  # `private`— and callers delete the notebooks missing from the response, so
  # an empty list would delete all the notebooks of the user.
  defp filter_private_repos(items, response) do
    public_items =
      Enum.filter(items, fn i ->
        case i["repository"]["private"] do
          false ->
            true

          _ ->
            Logger.error(
              "GithubAPI.Search fetched a private repo.\nRepo:\n" <>
                inspect(i) <> "\nFull GithubAPI's response:\n" <> inspect(response)
            )

            false
        end
      end)

    if items != [] and public_items == [] do
      Logger.error(
        "GithubAPI.Search discarded ALL items as private.\nFull GithubAPI's response:\n" <>
          inspect(response)
      )

      {:error, :all_items_discarded}
    else
      {:ok, public_items}
    end
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
