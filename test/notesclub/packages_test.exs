defmodule Notesclub.PackagesTest do
  use Notesclub.DataCase

  alias Notesclub.Packages

  alias Notesclub.Packages.Package

  import Notesclub.PackagesFixtures

  @invalid_attrs %{name: nil}

  test "list_packages/0 returns all packages" do
    package = package_fixture()
    assert Packages.list_packages() == [package]
  end

  test "get_package!/1 returns the package with given id" do
    package = package_fixture()
    assert Packages.get_package!(package.id) == package
  end

  describe "get_by_name/1" do
    test "returns the package when it exists" do
      package_fixture(%{name: "kino"})
      assert %Package{name: "kino"} = Packages.get_by_name("kino")
    end

    test "returns nil when the package does not exist" do
      assert Packages.get_by_name("NonExistentPackage") == nil
    end
  end

  describe "list_or_create_by_names/1" do
    test "returns packages" do
      package_fixture(%{name: "kino"})

      assert {:ok, [%Package{name: "kino"}, %Package{name: "axon"}]} =
               Packages.list_or_create_by_names(["kino", "axon"])
    end
  end

  test "create_package/1 with valid data creates a package" do
    valid_attrs = %{name: "some name"}

    assert {:ok, %Package{} = package} = Packages.create_package(valid_attrs)
    assert package.name == "some name"
  end

  test "create_package/1 with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = Packages.create_package(@invalid_attrs)
  end

  test "update_package/2 with valid data updates the package" do
    package = package_fixture()
    update_attrs = %{name: "some updated name"}

    assert {:ok, %Package{} = package} = Packages.update_package(package, update_attrs)
    assert package.name == "some updated name"
  end

  test "update_package/2 with invalid data returns error changeset" do
    package = package_fixture()
    assert {:error, %Ecto.Changeset{}} = Packages.update_package(package, @invalid_attrs)
    assert package == Packages.get_package!(package.id)
  end

  test "delete_package/1 deletes the package" do
    package = package_fixture()
    assert {:ok, %Package{}} = Packages.delete_package(package)
    assert_raise Ecto.NoResultsError, fn -> Packages.get_package!(package.id) end
  end

  test "change_package/1 returns a package changeset" do
    package = package_fixture()
    assert %Ecto.Changeset{} = Packages.change_package(package)
  end
end
