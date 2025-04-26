defmodule Notesclub.PublishLogsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notesclub.PublishLogs` context.
  """

  @doc """
  Generate a publish_log.
  """
  def publish_log_fixture(attrs \\ %{}) do
    {:ok, publish_log} =
      attrs
      |> Enum.into(%{
        platform: "some platform"
      })
      |> Notesclub.PublishLogs.create_publish_log()

    publish_log
  end
end
