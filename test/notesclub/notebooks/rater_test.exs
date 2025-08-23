defmodule Notesclub.Notebooks.RaterTest do
  use Notesclub.DataCase

  alias Notesclub.Notebooks.Rater
  alias Notesclub.Notebooks.Notebook

  describe "rate_notebook_interest/1" do
    test "returns error for notebook without content" do
      notebook = %Notebook{content: nil}
      assert {:ok, 0} = Rater.rate_notebook_interest(notebook)
    end

    test "returns error for notebook with empty content" do
      notebook = %Notebook{content: ""}
      assert {:ok, 0} = Rater.rate_notebook_interest(notebook)
    end

    test "rates a notebook" do
      notebook = %Notebook{
        title: "Advanced GenServer Tutorial",
        github_filename: "genserver_tutorial.livemd",
        content: """
        # Advanced GenServer Tutorial

        ...
        """
      }

      {:ok, number} = Rater.rate_notebook_interest(notebook)
      assert number > 0
      assert number <= 1000
    end
  end
end
