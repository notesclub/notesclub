defmodule Notesclub.ReqTools do
  @moduledoc """
  Makes an HTTP request unless we're in test env
  """

  def make_request(url) do
    case __MODULE__.requests_enabled?() do
      true -> Req.get(url)
      false -> {:ok, %Req.Response{status: 200, body: "whatever"}}
    end
  end

  # This function is mocked in some tests
  def requests_enabled? do
    case Application.get_env(:notesclub, :env) do
      :test -> false
      _ -> true
    end
  end
end
