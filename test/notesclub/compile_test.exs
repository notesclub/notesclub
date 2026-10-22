defmodule Notesclub.CompileTest do
  use ExUnit.Case, async: true

  test "compiles the selected branch only when an optional application is loaded" do
    for {library, expected} <- [
          {:elixir, :available},
          {:notesclub_missing_dependency, :unavailable}
        ] do
      ast =
        quote do
          require Notesclub.Compile

          Notesclub.Compile.only_if_loaded unquote(library) do
            :available
          else
            :unavailable
          end
        end

      assert {^expected, []} = Code.eval_quoted(ast)
    end
  end
end
