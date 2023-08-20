defmodule Notesclub.Workers.UrlContentSyncWorker do
  @moduledoc """
  Make one or two requests to Github and update:
  - notebooks.url
  - notebooks.content

  We try first to get the content from the notebook default branch url
  If it doesn't exist, then we settle for the notebook commit branch url
  """
  use Oban.Worker,
    queue: :default,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Notebooks.Urls
  alias Notesclub.Repos.Repo
  alias Notesclub.Workers.NotebookPackagesWorker
  alias Notesclub.Workers.RepoSyncWorker

  @doc """
  Sync url and content depending on notebook's urls

  ## Examples

      iex> perform((%Oban.Job{args: %{"notebook_id" => 1}})
      {:ok, :synced}

      iex> perform((%Oban.Job{args: %{"notebook_id" => 3}})
      {:cancel, "..."}

  """
  @spec perform(Oban.Job.t()) :: {:ok, :synced} | {:cancel, binary()}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notebook_id" => notebook_id}}) do
    with {:ok, notebook} <- load_notebook(notebook_id),
         {:ok, urls} <- get_urls(notebook),
         {:ok, attrs} <- attrs_for_update(notebook, urls) do
      update_notebook(notebook, attrs)
    end
  end

  defp load_notebook(notebook_id) do
    case Notebooks.get_notebook(notebook_id, preload: [:user, :repo]) do
      nil ->
        {:cancel, "notebook does NOT exist"}

      %Notebook{user: nil} ->
        {:cancel, "user is nil"}

      %Notebook{repo: nil} ->
        {:cancel, "repo is nil"}

      %Notebook{repo: %Repo{default_branch: nil} = repo} ->
        {:ok, _job} =
          %{repo_id: repo.id}
          |> RepoSyncWorker.new()
          |> Oban.insert()

        {:cancel, "No default branch. Enqueueing RepoSyncWorker."}

      notebook ->
        {:ok, notebook}
    end
  end

  defp get_urls(%Notebook{} = notebook) do
    case Urls.get_urls(notebook) do
      {:ok, urls} ->
        {:ok, urls}

      {:error, error} ->
        {:cancel, "get_urls/1 returned '#{error}'; notebook id: #{notebook.id}"}
    end
  end

  defp attrs_for_update(notebook, urls) do
    case make_get_request(urls.raw_default_branch_url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        title = Notebooks.extract_title(body)
        {:ok, %{content: body, title: title, url: urls.default_branch_url}}

      {:ok, %Req.Response{status: 404}} ->
        attrs_from_commit(notebook, urls)

      _ ->
        # Retry several times
        raise "request to notebook default branch url failed"
    end
  end

  defp attrs_from_commit(notebook, urls) do
    case make_get_request(urls.raw_commit_url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        title = Notebooks.extract_title(body)
        {:ok, %{content: body, title: title, url: nil}}

      {:ok, %Req.Response{status: 404}} ->
        {:cancel,
         "Neither notebook default branch url or commit url exists. The notebook id: #{notebook.id} was deleted or moved on Github"}

      _ ->
        # Retry job several times
        raise "request to notebook commit url failed"
    end
  end

  defp update_notebook(notebook, attrs) do
    case Notebooks.update_notebook(notebook, attrs) do
      {:ok, notebook} ->
        NotebookPackagesWorker.new(%{notebook_id: notebook.id})
        |> Oban.insert()

        {:ok, :synced}

      {:error, _} ->
        #  Retry job several times
        {:error, "Error saving the notebook id #{notebook.id}, attrs: #{inspect(attrs)}"}
    end
  end

  defp make_get_request(url) do
    url
    |> URI.encode()
    |> Req.get()
  end
end
