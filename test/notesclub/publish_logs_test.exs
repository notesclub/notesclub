defmodule Notesclub.PublishLogsTest do
  use Notesclub.DataCase

  alias Notesclub.PublishLogs

  describe "publish_logs" do
    alias Notesclub.PublishLogs.PublishLog

    import Notesclub.PublishLogsFixtures

    @invalid_attrs %{platform: nil}

    test "list_publish_logs/0 returns all publish_logs" do
      publish_log = publish_log_fixture()
      assert PublishLogs.list_publish_logs() == [publish_log]
    end

    test "get_publish_log!/1 returns the publish_log with given id" do
      publish_log = publish_log_fixture()
      assert PublishLogs.get_publish_log!(publish_log.id) == publish_log
    end

    test "create_publish_log/1 with valid data creates a publish_log" do
      valid_attrs = %{platform: "some platform"}

      assert {:ok, %PublishLog{} = publish_log} = PublishLogs.create_publish_log(valid_attrs)
      assert publish_log.platform == "some platform"
    end

    test "create_publish_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = PublishLogs.create_publish_log(@invalid_attrs)
    end

    test "update_publish_log/2 with valid data updates the publish_log" do
      publish_log = publish_log_fixture()
      update_attrs = %{platform: "some updated platform"}

      assert {:ok, %PublishLog{} = publish_log} = PublishLogs.update_publish_log(publish_log, update_attrs)
      assert publish_log.platform == "some updated platform"
    end

    test "update_publish_log/2 with invalid data returns error changeset" do
      publish_log = publish_log_fixture()
      assert {:error, %Ecto.Changeset{}} = PublishLogs.update_publish_log(publish_log, @invalid_attrs)
      assert publish_log == PublishLogs.get_publish_log!(publish_log.id)
    end

    test "delete_publish_log/1 deletes the publish_log" do
      publish_log = publish_log_fixture()
      assert {:ok, %PublishLog{}} = PublishLogs.delete_publish_log(publish_log)
      assert_raise Ecto.NoResultsError, fn -> PublishLogs.get_publish_log!(publish_log.id) end
    end

    test "change_publish_log/1 returns a publish_log changeset" do
      publish_log = publish_log_fixture()
      assert %Ecto.Changeset{} = PublishLogs.change_publish_log(publish_log)
    end
  end
end
