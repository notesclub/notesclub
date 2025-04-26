defmodule Notesclub.Workers.RegenerateSitemapsWorker do
  @moduledoc """
  Worker to regenerate sitemaps
  """

  use Oban.Worker

  alias NotesclubWeb.SitemapController

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    SitemapController.regenerate_sitemaps()
  end
end
