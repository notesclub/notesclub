defmodule Notesclub.Workers.ScheduledPostsTest do
  use Notesclub.DataCase

  import Notesclub.AccountsFixtures
  import Notesclub.HTTPStub
  import Notesclub.NotebooksFixtures
  import Plug.Conn

  alias Notesclub.PublishLogs
  alias Notesclub.Stars
  alias Notesclub.Workers.BlueskyScheduledPostWorker
  alias Notesclub.Workers.XScheduledPostWorker
  alias Notesclub.X.XTokens

  @moduletag :capture_log
  @moduletag app_env: [bluesky_handle: "notes.test", bluesky_password: "test-password"]
  setup :setup_http

  for {worker, platform} <- [{XScheduledPostWorker, "x"}, {BlueskyScheduledPostWorker, "bluesky"}] do
    @worker worker
    @platform platform

    test "#{platform} does nothing when no unpublished notebook is eligible" do
      notebook_fixture(%{content: "too short", ai_rating: 900})
      assert {:ok, "No non-shared notebook found"} = perform_job(@worker, %{})
      assert PublishLogs.list_publish_logs() == []
    end

    test "#{platform} publishes starred notebooks once, then falls back to AI ratings" do
      {:ok, _} = XTokens.create_token(%{access_token: "access"})
      author = user_fixture(%{name: "Notebook Author", twitter_username: "author"})

      starred =
        notebook_fixture(%{
          user_id: author.id,
          title: "Starred guide",
          ai_rating: 100,
          url: "https://github.com/author/repo/blob/main/starred.livemd",
          content: String.duplicate("x", 250)
        })

      rated =
        notebook_fixture(%{
          user_id: author.id,
          title: "Rated guide",
          ai_rating: 900,
          url: "https://github.com/author/repo/blob/main/rated.livemd",
          content: String.duplicate("x", 250)
        })

      {:ok, _} = Stars.toggle_star(starred, author)
      test_pid = self()

      Req.Test.stub(__MODULE__, fn conn ->
        if String.ends_with?(conn.request_path, "createSession") do
          Req.Test.json(conn, %{accessJwt: "access"})
        else
          body = read_json(conn)
          message = if @platform == "x", do: body["text"], else: body["record"]["text"]
          send(test_pid, {:published, message})
          Req.Test.json(put_status(conn, if(@platform == "x", do: 201, else: 200)), %{id: "post"})
        end
      end)

      assert :ok = perform_job(@worker, %{})
      assert_receive {:published, message}
      assert message =~ "Starred guide by"
      assert message =~ "https://notes.club/author/repo/starred"
      assert :ok = perform_job(@worker, %{})
      assert_receive {:published, message}
      assert message =~ "Rated guide by"
      assert {:ok, "No non-shared notebook found"} = perform_job(@worker, %{})
      logs = PublishLogs.list_publish_logs()
      assert Enum.sort(Enum.map(logs, & &1.notebook_id)) == Enum.sort([starred.id, rated.id])
      assert Enum.all?(logs, &(&1.platform == @platform))
    end

    test "#{platform} supports authors without social handles and does not record failed posts" do
      {:ok, _} = XTokens.create_token(%{access_token: "access"})
      author = user_fixture(%{name: nil, twitter_username: nil})
      notebook_fixture(%{user_id: author.id, ai_rating: 900, content: String.duplicate("x", 250)})
      Req.Test.stub(__MODULE__, &Req.Test.json(put_status(&1, 401), %{error: "unauthorized"}))
      assert {:error, message} = perform_job(@worker, %{})
      assert message =~ "Failed to post to"
      assert PublishLogs.list_publish_logs() == []
    end
  end
end
