defmodule Notesclub.Notebooks.AnalyserTest do
  use Notesclub.DataCase

  alias Notesclub.Notebooks.Analyser
  import Notesclub.NotebooksFixtures

  describe "analyse_notebook/1" do
    test "returns error for notebook without content" do
      notebook = notebook_fixture(%{content: nil})
      assert {:error, :no_content} = Analyser.analyse_notebook(notebook)
    end

    test "returns error for notebook with empty content" do
      notebook = notebook_fixture(%{content: ""})
      assert {:error, :no_content} = Analyser.analyse_notebook(notebook)
    end

    test "analyses a notebook" do
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

      {:ok, rating, tags} = Analyser.analyse_notebook(notebook)
      assert rating > 0
      assert rating <= 1000
      assert is_list(tags)
    end
  end
end
