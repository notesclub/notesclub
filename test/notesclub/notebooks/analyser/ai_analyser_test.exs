defmodule Notesclub.Notebooks.Analyser.AiAnalyserTest do
  use ExUnit.Case

  import Notesclub.HTTPStub
  import Plug.Conn

  alias Notesclub.Notebooks.Analyser.AiAnalyser
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Tags

  @moduletag :capture_log
  @moduletag app_env: [openrouter_api_key: "test-key"]
  setup :setup_http

  test "rejects missing and empty content without making an HTTP request" do
    for content <- [nil, ""] do
      assert {:error, :no_content} = AiAnalyser.analyse_notebook(%Notebook{content: content})
    end
  end

  test "sends the notebook and allowed tags and parses a structured rating" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.request_path == "/api/v1/chat/completions"
      assert get_req_header(conn, "authorization") == ["Bearer test-key"]
      body = read_json(conn)

      assert body["response_format"]["json_schema"]["schema"]["properties"]["tags"]["items"][
               "enum"
             ] ==
               Tags.list_tag_names()

      assert List.last(body["messages"])["content"] =~ "Title: GenServer guide"
      assert List.last(body["messages"])["content"] =~ "Filename: guide.livemd"
      assert List.last(body["messages"])["content"] =~ "use GenServer"
      Req.Test.json(conn, completion(Jason.encode!(%{rating: 850, tags: ["gen-server"]})))
    end)

    assert {:ok, 850, ["gen-server"]} =
             AiAnalyser.analyse_notebook(%Notebook{
               title: "GenServer guide",
               github_filename: "guide.livemd",
               content: "use GenServer"
             })
  end

  test "truncates large notebooks and supplies missing metadata" do
    Req.Test.stub(__MODULE__, fn conn ->
      content = read_json(conn)["messages"] |> List.last() |> Map.fetch!("content")
      assert content =~ "Title: Untitled"
      assert content =~ "Filename: unknown.livemd"
      assert content =~ String.duplicate("a", 150_000) <> "..."
      refute content =~ String.duplicate("a", 150_001)
      Req.Test.json(conn, completion(~s({"rating":0,"tags":[]})))
    end)

    assert {:ok, 0, []} =
             AiAnalyser.analyse_notebook(%Notebook{
               title: nil,
               content: String.duplicate("a", 150_001)
             })
  end

  test "rejects missing, empty, invalid, and out-of-range completions" do
    for {content, expected} <- [
          {nil, :nil_content},
          {"", :empty_content},
          {~s({"rating":1001,"tags":[]}), :invalid_response},
          {~s({"rating":-1,"tags":[]}), :invalid_response},
          {~s({"rating":"high","tags":[]}), :invalid_response},
          {~s({"rating":500,"tags":"ai"}), :invalid_response},
          {~s({"rating":500,"tags":["not-allowed"]}), :invalid_response},
          {~s({"rating":500,"tags":[1]}), :invalid_response},
          {~s({"tags":[]}), :invalid_response}
        ] do
      Req.Test.stub(__MODULE__, &Req.Test.json(&1, completion(content)))
      assert {:error, ^expected} = AiAnalyser.analyse_notebook(%Notebook{content: "notebook"})
    end

    Req.Test.stub(__MODULE__, &Req.Test.json(&1, completion("not JSON")))

    assert {:error, {:json_parse_error, %Jason.DecodeError{}}} =
             AiAnalyser.analyse_notebook(%Notebook{content: "notebook"})
  end

  test "returns API and transport errors" do
    Req.Test.stub(__MODULE__, &Req.Test.json(put_status(&1, 429), %{error: "rate limited"}))

    assert {:error, {:api_error, 429, %{"error" => "rate limited"}}} =
             AiAnalyser.analyse_notebook(%Notebook{content: "notebook"})

    Req.Test.stub(__MODULE__, &Req.Test.transport_error(&1, :timeout))

    assert {:error, {:request_failed, %Req.TransportError{reason: :timeout}}} =
             AiAnalyser.analyse_notebook(%Notebook{content: "notebook"})
  end

  @tag app_env: [openrouter_api_key: nil]
  test "requires an API key" do
    assert_raise RuntimeError, "no api key", fn ->
      AiAnalyser.analyse_notebook(%Notebook{content: "notebook"})
    end
  end

  defp completion(content), do: %{"choices" => [%{"message" => %{"content" => content}}]}
end
