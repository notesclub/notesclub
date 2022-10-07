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

  alias Notesclub.Workers.RepoSyncWorker
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Notebooks.Urls
  alias Notesclub.Repos.Repo
  alias Notesclub.ReqTools

  require Logger

  @doc """
  Sync url and content depending on notebook's urls

  ## Examples

      iex> perform((%Oban.Job{args: %{"notebook_id" => 1}})
      {:ok, :synced}

      iex> perform((%Oban.Job{args: %{"notebook_id" => 3}})
      {:cancel, "..."}

  """
  @spec perform(%Oban.Job{}) :: {:ok, :synced} | {:error, binary()} | {:cancel, binary()}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notebook_id" => notebook_id}}) do
    notebook_id
    |> Notebooks.get_notebook!(preload: [:user, :repo])
    |> enqueue_sync_repo_if_no_default_branch()
    |> get_urls()
    |> get_content()
    |> update_content_and_maybe_url()
  end

  defp enqueue_sync_repo_if_no_default_branch(%Notebook{repo: %Repo{default_branch: nil} = repo}) do
    {:ok, _job} =
      %{repo_id: repo.id}
      |> RepoSyncWorker.new()
      |> Oban.insert()

    {:cancel, "No default branch. Enqueueing RepoSyncWorker."}
  end

  defp enqueue_sync_repo_if_no_default_branch(%Notebook{} = notebook), do: %{notebook: notebook}

  defp get_urls({:cancel, error}), do: {:cancel, error}

  defp get_urls(data) do
    with {:ok, %Urls{} = urls} <- Urls.get_urls(data.notebook) do
      Map.put(data, :urls, urls)
    else
      {:error, error} ->
        Logger.error("get_urls/1 returned {:error, #{error}}; notebook.id=#{data.notebook.id}")
        {:cancel, error}
    end
  end

  defp get_content({:cancel, error}), do: {:cancel, error}

  defp get_content(data) do
    data
    |> make_default_branch_request()
    |> maybe_make_commit_request()
  end

  defp make_default_branch_request(data) do
    case ReqTools.make_request(data.urls.raw_default_branch_url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Map.put(data, :default_branch_content, body)

      {:ok, %Req.Response{status: 404}} ->
        data

      _ ->
        # Retry several times
        raise "request to notebook default branch url failed"
    end
  end

  defp maybe_make_commit_request(%{urls: %Urls{raw_commit_url: nil}}),
    do: {:cancel, "raw_commit_url is nil"}

  defp maybe_make_commit_request(%{default_branch_content: _} = data), do: data

  # Make the second request when default_branch_content is nil
  # Then, we'll need to settle for the commit_branch
  defp maybe_make_commit_request(data) do
    case ReqTools.make_request(data.urls.raw_commit_url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Map.put(data, :commit_content, body)

      {:ok, %Req.Response{status: 404}} ->
        Logger.error("Notebook (id: #{data.notebook.id}) deleted or moved on Github")
        {:cancel, "neither notebook default branch url or commit url exists"}

      _ ->
        # Retry job several times
        raise "request to notebook commit url failed"
    end
  end

  defp update_content_and_maybe_url({:cancel, error}), do: {:cancel, error}

  # Save content and url even if they are nil
  defp update_content_and_maybe_url(data) do
    attrs = attributes_to_update(data)

    with {:ok, _notebook} <- Notebooks.update_notebook(data.notebook, attrs) do
      {:ok, :synced}
    else
      {:error, _} ->
        Logger.error(
          "update_content_and_maybe_url/1 error updating notebook id #{data.notebook.id}, attrs: #{inspect(attrs)}"
        )

        #  Retry job several times
        {:error, "Error saving the notebook"}
    end
  end

  defp attributes_to_update(%{default_branch_content: default_branch_content, urls: urls}) do
    %{
      content: default_branch_content,
      url: urls.default_branch_url
    }
  end

  defp attributes_to_update(%{commit_content: commit_content}) do
    %{content: commit_content, url: nil}
  end
end
