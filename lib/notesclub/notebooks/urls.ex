defmodule Notesclub.Notebooks.Urls do
  @moduledoc """
  Generate Github notebooks' urls from github_html_url
  """
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Notebooks.Urls
  alias Notesclub.Repos.Repo
  alias Notesclub.Accounts.User

  defstruct [
    :notebook,
    :commit_url,
    :raw_commit_url,
    :default_branch_url,
    :raw_default_branch_url
  ]

  @doc """
  Generate the four notebook urls that we need

  ## Examples

      iex> get_urls(%Notebook{id: 1})
      {:ok, %{
        commit_url: "https://github.com/elixir-nx/axon/blob/7f1d1ab2e6c8a35edf3f58eae9182c4a149cd8d5/notebooks/vision/mnist.livemd",
        raw_commit_url: "https://raw.githubusercontent.com/elixir-nx/axon/7f1d1ab2e6c8a35edf3f58eae9182c4a149cd8d5/notebooks/vision/mnist.livemd",
        default_branch_url: "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd",
        raw_default_branch_url: "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd"
      }}

  """
  @spec get_urls(%Notebook{}) :: {:ok, %Urls{}} | {:error, binary()}
  def get_urls(nil), do: {:error, "notebook can't be nil"}

  def get_urls(%Notebook{repo: %Repo{default_branch: nil}}),
    do: {:error, "repo.default_branch can't be nil"}

  def get_urls(%Notebook{repo: %User{username: nil}}), do: {:error, "user.username can't be nil"}

  def get_urls(%Notebook{user: %User{}, repo: %Repo{}} = notebook) do
    notebook
    |> get_commit_url()
    |> get_raw_commit_url()
    |> get_default_branch_url()
    |> get_raw_default_branch_url()
  end

  def get_urls(%Notebook{}), do: {:error, "notebook must include user and repo preloaded."}

  @doc """
  Generates a raw_url from a github_html_url

  ## Examples

  iex> raw_url("https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd")
  "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd"

  iex> raw_url("https://no-github-url.com")
  nil
  """
  def raw_url(github_html_url) do
    if String.match?(github_html_url, ~r|^https://github.com/[^\/]+/[^\/]+/blob/|) do
      github_html_url
      |> String.replace(
        ~r|^https://github.com/|,
        "https://raw.githubusercontent.com/"
      )
      |> String.replace(
        ~r|/blob/|,
        "/"
      )
      |> URI.encode()
    end
  end

  # github_html_url is the url that returns Github Search API
  # It points to the sha/commit
  defp get_commit_url(%Notebook{} = notebook) do
    %Urls{
      notebook: notebook,
      commit_url: notebook.github_html_url
    }
  end

  defp get_raw_commit_url(%Urls{} = urls) do
    Map.put(urls, :raw_commit_url, urls.commit_url |> raw_url())
  end

  defp get_default_branch_url(%Urls{commit_url: nil}), do: nil

  defp get_default_branch_url(%Urls{notebook: %Notebook{repo: %Repo{default_branch: nil}}}),
    do: nil

  defp get_default_branch_url(%Urls{} = urls) do
    default_branch = urls.notebook.repo.default_branch
    url = default_branch_url(urls.commit_url, default_branch)
    Map.put(urls, :default_branch_url, url)
  end

  def default_branch_url(github_html_url, default_branch) do
    String.replace(github_html_url, ~r/\/blob\/[^\/]*\//, "/blob/#{default_branch}/")
  end

  defp get_raw_default_branch_url(%Urls{} = urls) do
    urls = Map.put(urls, :raw_default_branch_url, urls.default_branch_url |> raw_url())
    {:ok, urls}
  end
end
