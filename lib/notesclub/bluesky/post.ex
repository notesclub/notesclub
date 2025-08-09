defmodule Notesclub.Bluesky.Post do
  alias Notesclub.BlueskyApi

  def post(message) do
    BlueskyApi.post(message)
  end
end
