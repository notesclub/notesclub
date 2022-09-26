defmodule Notesclub.Compile do
  defmacro only_if_loaded(library, body) do
    if Application.spec(library) do
      body[:do]
    else
      body[:else]
    end
  end
end
