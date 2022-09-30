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
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Urls
  alias Notesclub.ReqTools

  defstruct notebook: nil, urls: %Urls{}, default_branch_content: nil, commit_content: nil

  require Logger

  @spec perform(%Oban.Job{}) :: {:ok, :synced} | {:error, binary()} | {:cancel, binary()}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notebook_id" => notebook_id}}) do
    notebook_id
    |> get_notebook()
    |> get_urls()
    |> get_content()
    |> update_content_and_maybe_url()
  end

  defp get_notebook(notebook_id) do
    notebook = Notebooks.get_notebook(notebook_id, preload: [:user, :repo])
    %Sync{notebook: notebook}
  end

  defp get_urls(%Sync{notebook: nil} = data), do: data

  defp get_urls(%Sync{} = data) do
    {:ok, urls} = Urls.get_urls(data.notebook)
    Map.put(data, :urls, urls)
  end

  defp get_content(%Sync{notebook: nil} = data), do: data

  defp get_content(data) do
    data
    |> make_default_branch_request()
    |> maybe_make_commit_request()
  end

  defp make_default_branch_request(%Sync{urls: %Urls{raw_default_branch_url: nil}} = data),
    do: data

  defp make_default_branch_request(%Sync{} = data) do
    case ReqTools.make_request(data.urls.raw_default_branch_url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Map.put(data, :default_branch_content, body)

      {:ok, %Req.Response{status: 404}} ->
        data

      _ ->
        # Retry several times
        {:error, "request to notebook default branch url failed"}
    end
  end

  defp maybe_make_commit_request(%Sync{urls: %Urls{raw_commit_url: nil}} = data), do: data

  # Make the second request when default_branch_content == nil
  # Then, we'll need to settle for the commit_branch
  defp maybe_make_commit_request(%Sync{default_branch_content: nil} = data) do
    case ReqTools.make_request(data.urls.raw_commit_url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Map.put(data, :commit_content, body)

      {:ok, %Req.Response{status: 404}} ->
        Logger.error("Notebook (id: #{data.notebook.id}) deleted or moved on Github")
        {:cancel, "neither notebook default branch url or commit url"}

      _ ->
        # Retry job several times
        {:error, "request to notebook commit url failed"}
    end
  end

  # Do NOT make the second request when default_branch_content != nil
  #  Because we prefer the content of the default branch!
  defp maybe_make_commit_request(%Sync{} = data), do: data

  # Notebook doesn't exists, skipping
  defp update_content_and_maybe_url(%Sync{notebook: nil}), do: {:cancel, "No notebook, skipping."}

  defp update_content_and_maybe_url({:error, msg}), do: {:error, msg}
  defp update_content_and_maybe_url({:cancel, msg}), do: {:cancel, msg}

  # Save content and url even if they are nil
  defp update_content_and_maybe_url(%Sync{} = data) do
    attrs = attributes_to_update(data)

    case Notebooks.update_notebook(data.notebook, attrs) do
      {:ok, _notebook} ->
        {:ok, :synced}

      _ ->
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
