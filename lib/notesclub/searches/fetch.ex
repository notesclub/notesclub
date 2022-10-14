defmodule Notesclub.Searches.Fetch do
  alias Notesclub.Searches.Fetch
  alias Notesclub.Searches.Fetch.Options

  require Logger

  defstruct options: Options, url: nil, response: nil, notebooks_data: nil, errors: %{}

  @doc """

  Gets files with 'livemd' extension from Fetch.

  ## Example
  iex> Notesclub.Searches.Fetch.get(%Options{per_page: 10, page: 1, order: "asc"})
  {:ok,
   %Fetch{
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
  @spec get(%Options{}) :: {:ok, %Fetch{}} | {:error, %Fetch{}}
  def get(%Options{} = options) do
    options
    |> build_url()
    |> make_request()
    |> extract_notebooks_data()
  end

  defp extract_notebooks_data(%Fetch{response: response, errors: errors} = fetch) do
    cond do
      errors[:github_api_key] == ["is missing"] && __MODULE__.check_github_api_key() ->
        {:error, fetch}

      true ->
        prepare_data(fetch, response.body["items"])
    end
  end

  defp prepare_data(%Fetch{response: response} = fetch, nil) do
    Logger.error("Fetch.Search, response: " <> inspect(response))
    {:error, fetch}
  end

  defp prepare_data(%Fetch{response: response} = fetch, items) do
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

    {:ok, Map.put(fetch, :notebooks_data, notebooks_data)}
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
            "Fetch.Search fetched a private repo.\nRepo:\n" <>
              inspect(i) <> "\nFull Fetch's response:\n" <> inspect(response)
          )

          false
      end
    end)
  end

  defp build_url(%Options{per_page: per_page, page: page, order: order} = options) do
    %Fetch{
      url:
        "https://api.github.com/search/code?q=extension:livemd&per_page=#{per_page}&page=#{page}&sort=indexed&order=#{order}",
      options: options
    }
  end

  defp make_request(%Fetch{} = fetch) do
    github_api_key = Application.get_env(:notesclub, :github_api_key)
    env = Application.get_env(:notesclub, :env)

    cond do
      github_api_key == nil && __MODULE__.check_github_api_key() ->
        Map.put(fetch, :errors, %{github_api_key: ["is missing"]})

      true ->
        response =
          Req.get!(
            url(fetch, env == :test),
            headers: [
              Accept: ["application/vnd.github+json"],
              Authorization: ["token #{github_api_key}"]
            ]
          )

        Map.put(fetch, :response, response)
    end
  end

  #  Don't make requests to Github in test env
  defp url(%Fetch{}, true), do: ""
  defp url(%Fetch{} = fetch, false), do: fetch.url

  # We can mock this in tests
  @spec check_github_api_key :: true
  def check_github_api_key, do: true
end
