defmodule Notesclub.HTTPStub do
  @moduledoc "Helpers for testing HTTP clients without external network requests."

  import ExUnit.Callbacks

  def setup_http(%{module: module} = context) do
    previous_options = Req.default_options()
    Req.default_options(plug: {Req.Test, module}, retry: false)
    Req.Test.stub(module, fn conn -> raise "Unexpected HTTP request: #{conn.request_path}" end)

    previous_env =
      for {key, value} <- Map.get(context, :app_env, []) do
        previous = Application.fetch_env(:notesclub, key)
        Application.put_env(:notesclub, key, value)
        {key, previous}
      end

    on_exit(fn ->
      Req.default_options(previous_options)

      Enum.each(previous_env, &restore_env/1)
    end)

    :ok
  end

  defp restore_env({key, {:ok, value}}), do: Application.put_env(:notesclub, key, value)
  defp restore_env({key, :error}), do: Application.delete_env(:notesclub, key)

  def read_json(conn) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    Jason.decode!(body)
  end
end
