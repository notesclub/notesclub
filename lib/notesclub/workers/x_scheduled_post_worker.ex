defmodule Notesclub.Workers.XScheduledPostWorker do
  @moduledoc """
  Worker to post scheduled messages to X (Twitter) using the stored access token
  Scheduled via cron to run every 8 hours
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  alias Notesclub.XAPI
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Paths
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Accounts.User

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    case Notebooks.get_most_recent_clapped_notebook() do
      nil ->
        {:ok, "No notebook found"}

      notebook ->
        path = Paths.url_to_path(notebook)
        message = get_message(notebook, path)

        case XAPI.post_with_stored_token(message) do
          {:ok, _response} -> :ok
          {:error, reason} -> {:error, "Failed to post to X: #{inspect(reason)}"}
        end
    end
  end

  defp get_message(notebook, path) do
    "Elixir livebook: #{notebook.title} by #{notebook.user.username} https://notes.club#{path}"
  end

  # defp get_message(%Notebook{user: %User{twitter_username: nil}} = notebook, path) do
  #   "Elixir livebook: #{notebook.title} by #{notebook.user.username} https://notes.club#{path}"
  # end

  # defp get_message(notebook, path) do
  #   "Elixir livebook: #{notebook.title} by @#{notebook.user.twitter_username} https://notes.club#{path}"
  # end
end
