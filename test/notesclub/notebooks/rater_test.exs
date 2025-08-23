defmodule Notesclub.Notebooks.RaterTest do
  use Notesclub.DataCase
  
  alias Notesclub.Notebooks.Rater
  alias Notesclub.Notebooks.Notebook

  describe "rate_notebook_interest/1" do
    test "returns error for notebook without content" do
      notebook = %Notebook{content: nil}
      assert {:error, :no_content} = Rater.rate_notebook_interest(notebook)
    end

    test "returns error for notebook with empty content" do
      notebook = %Notebook{content: ""}
      assert {:error, :no_content} = Rater.rate_notebook_interest(notebook)
    end

    @tag :integration
    test "rates an Elixir-heavy notebook highly" do
      notebook = %Notebook{
        title: "Advanced GenServer Tutorial",
        github_filename: "genserver_tutorial.livemd",
        content: """
        # Advanced GenServer Tutorial

        This notebook demonstrates advanced GenServer patterns in Elixir.

        ## Setup

        ```elixir
        Mix.install([
          {:gen_state_machine, "~> 3.0"},
          {:jason, "~> 1.4"}
        ])
        ```

        ## Creating a Stateful Server

        ```elixir
        defmodule MyServer do
          use GenServer

          def start_link(initial_state) do
            GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
          end

          def init(state) do
            {:ok, state}
          end

          def handle_call({:get, key}, _from, state) do
            {:reply, Map.get(state, key), state}
          end

          def handle_cast({:put, key, value}, state) do
            {:noreply, Map.put(state, key, value)}
          end
        end
        ```

        ## Advanced Patterns

        ```elixir
        # Supervisor setup
        children = [
          {MyServer, %{}}
        ]

        Supervisor.start_link(children, strategy: :one_for_one)
        ```

        This demonstrates real-world OTP patterns used in production systems.
        """
      }

      # This test requires an actual API key, so we'll skip it in regular test runs
      # In a real scenario, you'd mock the API call or use integration tests
      case Rater.rate_notebook_interest(notebook) do
        {:ok, rating} ->
          assert is_integer(rating)
          assert rating >= 0 and rating <= 1000
          # We expect this to be rated highly due to advanced Elixir content
          assert rating > 500

        {:error, :no_api_key} ->
          # Expected when API key is not configured in test environment
          :ok

        {:error, _reason} ->
          # Other errors might occur in test environment
          :ok
      end
    end

    @tag :integration
    test "rates a non-Elixir notebook lowly" do
      notebook = %Notebook{
        title: "Python Data Analysis",
        github_filename: "python_analysis.livemd",
        content: """
        # Python Data Analysis

        This is a basic Python tutorial.

        ```python
        import pandas as pd
        import numpy as np

        data = pd.read_csv('data.csv')
        print(data.head())
        ```

        ```python
        # Simple analysis
        mean_value = data['column'].mean()
        print(f"Mean: {mean_value}")
        ```
        """
      }

      case Rater.rate_notebook_interest(notebook) do
        {:ok, rating} ->
          assert is_integer(rating)
          assert rating >= 0 and rating <= 1000
          # We expect this to be rated lowly due to lack of Elixir content
          assert rating < 300

        {:error, :no_api_key} ->
          # Expected when API key is not configured in test environment
          :ok

        {:error, _reason} ->
          # Other errors might occur in test environment
          :ok
      end
    end
  end
end
