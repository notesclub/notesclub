defmodule Notesclub.Searches.Remove do
  require Logger

  alias Notesclub.Searches

  @number_of_days_to_keep_search_results 30

   # public function so we can mock it in tests
   def number_of_days_to_keep_search_results(),
    do: @number_of_days_to_keep_search_results

  def eliminate() do
    {count, nil} = Timex.now()
    |> Timex.beginning_of_day()
    |> Timex.shift(days: -@number_of_days_to_keep_search_results)
    |> Searches.delete_by_date()

    Logger.info("#{count} search records remove.")
  end
end
