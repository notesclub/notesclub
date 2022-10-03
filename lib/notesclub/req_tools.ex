defmodule Notesclub.ReqTools do
  @moduledoc """
  Makes an HTTP request unless we're in test env
  """

  # TODO: Check how to disable all http requests by default in tests
  # Cassettes? Mock Server depending on the url?
  # Then, delete this
  def make_request(url) do
    case __MODULE__.requests_enabled?() do
      true -> Req.get(url)
      false -> {:ok, %Req.Response{status: 200, body: "whatever"}}
    end
  end

  # This function is mocked in some tests
  def requests_enabled?() do
    case Application.get_env(:notesclub, :env) do
      :test -> false
      _ -> true
    end
  end
end
