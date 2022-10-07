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

  alias Notesclub.Workers.UrlContentSyncWorker, as: Sync
  alias Notesclub.Workers.RepoSyncWorker
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Notebooks.Urls
  alias Notesclub.Repos.Repo
  alias Notesclub.ReqTools

  defstruct [:notebook, :urls, :default_branch_content, :commit_content, :cancel]

  require Logger

  @doc """
  Sync url and content depending on notebook's urls

  ## Examples

      iex> perform((%Oban.Job{args: %{"notebook_id" => 1}})
      {:ok, :synced}

      iex> perform((%Oban.Job{args: %{"notebook_id" => 2}})
      {:error, "..."}

      iex> perform((%Oban.Job{args: %{"notebook_id" => 3}})
      {:cancel, "..."}

  """
  @spec perform(%Oban.Job{}) :: {:ok, :synced} | {:error, binary()} | {:cancel, binary()}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notebook_id" => notebook_id}}) do
    notebook_id
    |> get_notebook()
    |> enqueue_sync_repo_if_no_default_branch()
    |> get_urls()
    |> get_content()
    |> update_content_and_maybe_url()
  end

  defp get_notebook(notebook_id) do
    with %Notebook{} = notebook <- Notebooks.get_notebook(notebook_id, preload: [:user, :repo]) do
      %Sync{notebook: notebook}
    else
      nil -> %Sync{cancel: "No notebook. Skipping."}
    end
  end

  defp enqueue_sync_repo_if_no_default_branch(%Sync{} = data) do
    with %{notebook: %Notebook{repo: %Repo{default_branch: nil} = repo}} <- data do
      {:ok, _job} =
        %{repo_id: repo.id}
        |> RepoSyncWorker.new()
        |> Oban.insert()

      %Sync{cancel: "No default branch. Enqueueing RepoSyncWorker."}
    end
  end

  defp get_urls(%Sync{cancel: error} = data) when is_binary(error), do: data

  defp get_urls(%Sync{} = data) do
    with {:ok, %Urls{} = urls} <- Urls.get_urls(data.notebook) do
      %{data | urls: urls}
    else
      {:error, error} ->
        Logger.error("get_urls/1 returned {:error, #{error}}; notebook.id=#{data.notebook.id}")
        %{data | cancel: error}
    end
  end

  defp get_content(%Sync{cancel: error} = data) when is_binary(error), do: data

  defp get_content(data) do
    with %Sync{default_branch_content: nil} <- make_default_branch_request(data) do
      maybe_make_commit_request(data)
    end
  end

  defp make_default_branch_request(%Sync{} = data) do
    case ReqTools.make_request(data.urls.raw_default_branch_url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        %{data | default_branch_content: body}

      {:ok, %Req.Response{status: 404}} ->
        data

      _ ->
        # Retry several times
        raise "request to notebook default branch url failed"
    end
  end

  defp maybe_make_commit_request(%Sync{urls: %Urls{raw_commit_url: nil}} = data), do: data

  # Make the second request when default_branch_content is nil
  # Then, we'll need to settle for the commit_branch
  defp maybe_make_commit_request(%Sync{} = data) do
    case ReqTools.make_request(data.urls.raw_commit_url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        %{data | commit_content: body}

      {:ok, %Req.Response{status: 404}} ->
        Logger.error("Notebook (id: #{data.notebook.id}) deleted or moved on Github")
        %{data | cancel: "neither notebook default branch url or commit url exists"}

      _ ->
        # Retry job several times
        raise "request to notebook commit url failed"
    end
  end

  defp update_content_and_maybe_url(%Sync{cancel: error}) when is_binary(error),
    do: {:cancel, error}

  # Save content and url even if they are nil
  defp update_content_and_maybe_url(%Sync{} = data) do
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

  defp attributes_to_update(%Sync{default_branch_content: nil} = data) do
    %{content: data.commit_content, url: nil}
  end

  defp attributes_to_update(%Sync{} = data) do
    %{
      content: data.default_branch_content,
      url: data.urls.default_branch_url
    }
  end
end
