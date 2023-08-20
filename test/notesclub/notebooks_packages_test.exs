defmodule Notesclub.NotebooksPackagesTest do
  use Notesclub.DataCase

  import Notesclub.NotebooksFixtures
  import Notesclub.PackagesFixtures

  alias Notesclub.Notebooks
  alias Notesclub.NotebooksPackages
  alias Notesclub.Packages
  alias Notesclub.Packages.Package

  @content """
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

  describe "link!/2" do
    test "links notebook to packages" do
      notebook = notebook_fixture()
      notebook = Notebooks.get_notebook(notebook.id, preload: :packages)

      package1 = package_fixture(%{name: "kino"})
      package2 = package_fixture(%{name: "jason"})
      package3 = package_fixture(%{name: "req"})

      assert NotebooksPackages.link!(notebook, [package1, package2]) == :ok
      notebook = Notebooks.get_notebook(notebook.id, preload: :packages)

      assert Enum.sort(notebook.packages, &(&1.id <= &2.id)) ==
               Enum.sort([package1, package2], &(&1.id <= &2.id))

      assert NotebooksPackages.link!(notebook, [package2, package3]) == :ok
      notebook = Notebooks.get_notebook(notebook.id, preload: :packages)

      assert Enum.sort(notebook.packages, &(&1.id <= &2.id)) ==
               Enum.sort([package2, package3], &(&1.id <= &2.id))
    end
  end

  describe "link_from_notebook!/1" do
    setup do
      {:ok, notebook: notebook_fixture(%{content: @content})}
    end

    test "updates the notebook's packages based on its content", %{notebook: notebook} do
      #  One package exists
      %Package{} = package_fixture(%{name: "req"})

      assert :ok == Notesclub.NotebooksPackages.link_from_notebook!(notebook.id)

      updated_notebook = Notebooks.get_notebook(notebook.id, preload: :packages)
      package_names = Enum.map(updated_notebook.packages, & &1.name)

      assert ["jason", "req"] == Enum.sort(package_names)
    end

    test "creates new packages if they don't exist", %{notebook: notebook} do
      # Ensure the package doesn't exist yet
      assert nil == Packages.get_by_name("req")

      assert :ok == Notesclub.NotebooksPackages.link_from_notebook!(notebook.id)

      # Check that the new package has been created
      assert %Package{name: "req"} = Packages.get_by_name("req")
    end

    test "raises an error if the notebook doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Notesclub.NotebooksPackages.link_from_notebook!(-1)
      end
    end
  end
end
