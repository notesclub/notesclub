defmodule NotesclubWeb.Plugs.RateLimitTest do
  use ExUnit.Case, async: false

  import Plug.Test

  alias NotesclubWeb.Plugs.RateLimit
  alias NotesclubWeb.RateLimiter

  setup do
    RateLimiter.reset()
    on_exit(&RateLimiter.reset/0)
  end

  test "limits matching client and route buckets" do
    opts = RateLimit.init(bucket: :test, limit: 2, period_ms: 60_000)

    assert %{halted: false} = conn(:get, "/expensive") |> RateLimit.call(opts)
    assert %{halted: false} = conn(:get, "/expensive") |> RateLimit.call(opts)

    blocked = conn(:get, "/expensive") |> RateLimit.call(opts)
    assert blocked.halted
    assert blocked.status == 429
    assert blocked.resp_body == "Too Many Requests"

    assert %{halted: false} = conn(:get, "/different") |> RateLimit.call(opts)
  end

  test "starts a new window after the configured period" do
    key = {:test, make_ref()}
    assert RateLimiter.allow?(key, 1, 1)
    refute RateLimiter.allow?(key, 1, 1)
    Process.sleep(2)
    assert RateLimiter.allow?(key, 1, 1)
  end
end
