defmodule Notesclub.Workers.XScheduledPostWorker do
  @moduledoc """
  Worker to post scheduled messages to X (Twitter) using the stored access token
  Scheduled via cron to run every 8 hours
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  alias Notesclub.X
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Paths
  alias Notesclub.PublishLogs

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    case Notebooks.get_most_clapped_recent_notebook() do
      nil ->
        {:ok, "No notebook found"}

      notebook ->
        path = Paths.url_to_path(notebook)
        message = get_message(notebook, path)

        case X.post(message) do
          {:ok, _response} ->
            PublishLogs.create_publish_log(%{
              platform: "x",
              notebook_id: notebook.id,
              user_id: notebook.user_id
            })

            :ok

          {:error, reason} ->
            {:error, "Failed to post to X: #{inspect(reason)}"}
        end
    end
  end

  defp get_message(notebook, path) do
    "#{notebook.title} by #{notebook.user.username} https://notes.club#{path}"
  end

  # defp get_message(%Notebook{user: %User{twitter_username: nil}} = notebook, path) do
  #   "#{notebook.title} by #{notebook.user.username} https://notes.club#{path}"
  # end

  # defp get_message(notebook, path) do
  #   "#{notebook.title} by @#{notebook.user.twitter_username} https://notes.club#{path}"
  # end
end
