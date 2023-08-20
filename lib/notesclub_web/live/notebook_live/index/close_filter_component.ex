defmodule NotesclubWeb.NotebookLive.Index.CloseFilterComponent do
  @moduledoc """
  Badge that indicates the active filter.
  Visitors can close it to go back.
  """

  use NotesclubWeb, :live_component

  def filter_type(%{package: package, author: nil}) do
    "#{package} (hex package)"
  end

  def filter_type(%{author: author, repo: nil}) do
    "@#{author}"
  end

  def filter_type(%{repo: repo, author: author}) do
    "@#{author}/#{repo}"
  end
end
