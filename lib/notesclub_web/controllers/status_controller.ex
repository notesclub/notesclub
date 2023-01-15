defmodule NotesclubWeb.StatusController do
  use NotesclubWeb, :controller

  import Notesclub.Notebooks, only: [get_latest_notebook: 0]

  def status(conn, _params) do
    notebook = get_latest_notebook()

    if Timex.after?(notebook.inserted_at, Timex.now() |> Timex.shift(hours: -48)) do
      text(conn, "OK")
    else
      text(conn, "ERROR. The most recent notebook was created on the #{notebook.inserted_at}")
    end
  end
end
