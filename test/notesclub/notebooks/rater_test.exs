defmodule Notesclub.Notebooks.RaterTest do
  use Notesclub.DataCase

  alias Notesclub.Notebooks.Rater
  import Notesclub.NotebooksFixtures

  describe "rate_notebook_interest/1" do
    test "returns 0 for notebook without content" do
      notebook = notebook_fixture(%{content: nil})
      assert {:ok, 0} = Rater.rate_notebook_interest(notebook)
    end

    test "returns 0 for notebook with empty content" do
      notebook = notebook_fixture(%{content: ""})
      assert {:ok, 0} = Rater.rate_notebook_interest(notebook)
    end

    test "rates a notebook" do
      notebook =
        notebook_fixture(%{
          title: "Advanced GenServer Tutorial",
          github_filename: "genserver_tutorial.livemd",
          content: """
          # Advanced GenServer Tutorial

          This tutorial covers advanced GenServer patterns in Elixir.

          ```elixir
          defmodule MyGenServer do
            use GenServer

            def start_link(opts) do
              GenServer.start_link(__MODULE__, :ok, opts)
            end

            def init(:ok) do
              {:ok, %{}}
            end
          end
          ```
          """
        })

      {:ok, number} = Rater.rate_notebook_interest(notebook)
      assert number > 0
      assert number <= 1000
    end
  end
end
