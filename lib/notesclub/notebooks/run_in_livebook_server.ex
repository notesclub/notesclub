defmodule Notesclub.Notebooks.RunInLivebookServer do
  @moduledoc """
  Handle the atomic incrementing of the `run_in_livebook_count` in notebooks.
  """

  use GenServer

  alias Notesclub.Notebooks

  # API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def increase_count(notebook_id) do
    GenServer.call(__MODULE__, {:increase_count, notebook_id})
  end

  # GenServer Callbacks

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_call({:increase_count, notebook_id}, _from, state) do
    {:reply, Notebooks.increase_run_in_livebook_count(notebook_id), state}
  end
end
