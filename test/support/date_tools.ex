defmodule DateTools do
  @moduledoc """
  Date helpers
  """

  def days_ago(num_days) do
    NaiveDateTime.utc_now() |> NaiveDateTime.add(-60 * 60 * 24 * num_days)
  end
end
