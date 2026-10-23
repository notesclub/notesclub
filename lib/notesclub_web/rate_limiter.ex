defmodule NotesclubWeb.RateLimiter do
  @moduledoc false

  use GenServer

  @cleanup_interval :timer.minutes(1)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def allow?(key, limit, period_ms)
      when is_integer(limit) and limit > 0 and is_integer(period_ms) and period_ms > 0 do
    GenServer.call(__MODULE__, {:allow?, key, limit, period_ms})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @impl true
  def init(state) do
    schedule_cleanup()
    {:ok, state}
  end

  @impl true
  def handle_call({:allow?, key, limit, period_ms}, _from, state) do
    now = System.monotonic_time(:millisecond)

    case Map.get(state, key) do
      {started_at, count, ^period_ms} when now - started_at < period_ms and count >= limit ->
        {:reply, false, state}

      {started_at, count, ^period_ms} when now - started_at < period_ms ->
        {:reply, true, Map.put(state, key, {started_at, count + 1, period_ms})}

      _expired_or_new ->
        {:reply, true, Map.put(state, key, {now, 1, period_ms})}
    end
  end

  def handle_call(:reset, _from, _state), do: {:reply, :ok, %{}}

  @impl true
  def handle_info(:cleanup, state) do
    now = System.monotonic_time(:millisecond)

    state =
      Map.reject(state, fn {_key, {started_at, _count, period_ms}} ->
        now - started_at >= period_ms
      end)

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
