defmodule Notesclub.Workers.XScheduledPostWorker do
  @moduledoc """
  Worker to post scheduled messages to X (Twitter) using the stored access token
  Scheduled via cron to run every 8 hours
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  require Logger

  alias Notesclub.Accounts.User
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Notebooks.Paths
  alias Notesclub.PublishLogs
  alias Notesclub.X

  @platform "x"

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    case Notebooks.get_most_starred_recent_notebook(@platform) do
      nil ->
        {:ok, "No notebook found"}

      notebook ->
        path = Paths.url_to_path(notebook)
        message = get_message(notebook, path)

        case X.post(message) do
          {:ok, _response} ->
            create_publish_log(notebook)

          {:error, reason} ->
            {:error, "Failed to post to X: #{inspect(reason)}"}
        end
    end
  end

  defp get_message(%Notebook{user: %User{twitter_username: nil}} = notebook, path) do
    "#{notebook.title} by #{notebook.user.name} https://notes.club#{path}"
  end

  defp get_message(notebook, path) do
    "#{notebook.title} by @#{notebook.user.twitter_username} https://notes.club#{path}"
  end

  defp create_publish_log(notebook) do
    case PublishLogs.create_publish_log(%{
           platform: @platform,
           notebook_id: notebook.id,
           user_id: notebook.user_id
         }) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error(
          "Failed to create_publish_log after posting to X (be aware: we might publish repeated notebooks): #{inspect(reason)}"
        )

        {:error, "Failed to create publish log: #{inspect(reason)}"}
    end
  end
end
