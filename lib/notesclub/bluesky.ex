defmodule Notesclub.Bluesky do
  @moduledoc """
  Main interface for Bluesky functionality
  """
  alias Notesclub.Bluesky.Api

  defdelegate post(message), to: Api
end
