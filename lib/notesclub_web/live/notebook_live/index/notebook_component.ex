defmodule NotesclubWeb.NotebookLive.Index.NotebookComponent do
  use NotesclubWeb, :live_component

  alias Notesclub.StringTools
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook

  defp format_date(%Notebook{inserted_at: inserted_at}) do
    %NaiveDateTime{year: year, month: month, day: day} = inserted_at
    "#{year}-#{month}-#{day}"
  end
end
