defmodule Notesclub.Workers.XScheduledPostWorker do
  @moduledoc """
  Worker to post scheduled messages to X (Twitter) using the stored access token
  Scheduled via cron to run every 8 hours
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  alias Notesclub.XAPI

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message" => message}}) do
    message = message <> " " <> (DateTime.utc_now() |> DateTime.to_string())
    IO.inspect("Pushing message to X: #{message}")

    case XAPI.post_with_stored_token(message) do
      {:ok, _response} -> :ok
      {:error, reason} -> {:error, "Failed to post to X: #{inspect(reason)}"}
    end
  end
end
