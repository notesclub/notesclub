defmodule NotesclubWeb.Plugs.RateLimit do
  @moduledoc false

  import Plug.Conn

  alias NotesclubWeb.RateLimiter

  def init(opts) do
    %{
      bucket: Keyword.fetch!(opts, :bucket),
      limit: Keyword.fetch!(opts, :limit),
      period_ms: Keyword.fetch!(opts, :period_ms)
    }
  end

  def call(conn, %{bucket: bucket, limit: limit, period_ms: period_ms}) do
    key = {bucket, client_identity(conn), conn.method, conn.request_path}

    if RateLimiter.allow?(key, limit, period_ms) do
      conn
    else
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(429, "Too Many Requests")
      |> halt()
    end
  end

  defp client_identity(%{assigns: %{current_user: %{id: id}}}), do: {:user, id}
  defp client_identity(conn), do: {:ip, conn.remote_ip}
end
