defmodule Notesclub.Bluesky do
  alias Notesclub.Bluesky.Post

  defdelegate post(message), to: Post
end
