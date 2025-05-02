defmodule Notesclub.PublishLogsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notesclub.PublishLogs` context.
  """

  import Notesclub.NotebooksFixtures

  @doc """
  Generate a publish_log.
  """
  def publish_log_fixture(attrs \\ %{}) do
    notebook_id = if attrs[:notebook_id], do: attrs[:notebook_id], else: notebook_fixture().id

    {:ok, publish_log} =
      attrs
      |> Enum.into(%{
        platform: "some platform",
        notebook_id: notebook_id
      })
      |> Notesclub.PublishLogs.create_publish_log()

    publish_log
  end
end
