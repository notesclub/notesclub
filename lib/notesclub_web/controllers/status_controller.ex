defmodule NotesclubWeb.StatusController do
  use NotesclubWeb, :controller

  import Notesclub.Notebooks, only: [get_latest_notebook: 0]

  def status(conn, _params) do
    notebook = get_latest_notebook()

    msg = "The most recent notebook was created on the #{notebook.inserted_at}"

    if Timex.after?(notebook.inserted_at, Timex.now() |> Timex.shift(hours: -48)) do
      text(conn, "OK: #{msg}")
    else
      text(conn, "ERROR: #{msg}")
    end
  end
end
