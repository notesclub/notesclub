defmodule Notesclub.Notebooks.AnalyserTest do
  use Notesclub.DataCase

  alias Notesclub.Notebooks.Analyser
  import Notesclub.NotebooksFixtures

  defmodule InvalidTagAnalyser do
    def analyse_notebook(_notebook), do: {:ok, 999, ["ai", "not-allowed"]}
  end

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

    test "rolls back the rating when tag persistence fails" do
      previous = Application.get_env(:notesclub, :notebook_analyser_implementation)
      Application.put_env(:notesclub, :notebook_analyser_implementation, InvalidTagAnalyser)

      on_exit(fn ->
        Application.put_env(:notesclub, :notebook_analyser_implementation, previous)
      end)

      notebook = notebook_fixture(%{ai_rating: 321})

      assert {:error, :error} = Analyser.analyse_notebook(notebook)
      assert Notesclub.Notebooks.get_notebook!(notebook.id).ai_rating == 321
    end
  end
end
