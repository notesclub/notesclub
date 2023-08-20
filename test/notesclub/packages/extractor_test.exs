defmodule Notesclub.Packages.ExtractorTest do
  use Notesclub.DataCase

  alias Notesclub.Packages.Extractor

  test "extract hex packages" do
    content = """
    <!-- livebook:{"persist_outputs":true} -->

    # Search on Google via Serper

    ```elixir
    Mix.install([
      {:req, "~> 0.3.11"},
      {:jason, "~> 1.4"}
    ])
    ```

    <!-- livebook:{"output":true} -->

    ```
    :ok
    ```

    ## Section
    """

    assert Extractor.extract_packages(content) == ["req", "jason"]
  end

  test "should only include packages within Mix.install" do
    content = """
      Mix.install(
        [
          {:openai, "~> 0.1.1"},
          {:kino, "~> 0.6.1"}
        ],
        config: [
          openai: [
            api_key: "...",
            organisation_key: "..."
          ]
        ]
      )
      ...
      {:whatever, "~> 0.1.1"}
    """

    #  Should NOT include "whatever"
    assert Extractor.extract_packages(content) == ["openai", "kino"]
  end

  test "should not add duplicated packages" do
    content = """
      Mix.install(
        [
          {:openai, "~> 0.1.1"},
          # {:kino, "~> 0.5"}
          {:kino, "~> 0.6.1"}
        ],
        config: [
          openai: [
            api_key: "...",
            organisation_key: "..."
          ]
        ]
      )
      ...
      {:whatever, "~> 0.1.1"}
    """

    #  Should NOT include "kino" twice
    assert Extractor.extract_packages(content) == ["openai", "kino"]
  end

  test "extracts from github" do
    content = """
    Mix.install([{:nx, github: "elixir-nx/nx", sparse: "nx"}])
    ...
    """

    assert Extractor.extract_packages(content) == ["nx"]
  end
end
