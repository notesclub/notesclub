defmodule Notesclub.StringTools do
  def truncate(input, max_length) when is_binary(input) do
    if String.length(input) > max_length do
      String.slice(input, 0, max_length) <> "..."
    else
      input
    end
  end
end
