defmodule Notesclub.StringToolsTest do
  use Notesclub.DataCase

  alias Notesclub.StringTools

  describe "StringTools" do
    test "truncate/1 truncates and adds ..." do
      assert StringTools.truncate("0123456789abc", 3) == "0123..."
      assert StringTools.truncate("0123456789abc", 5) == "01234..."
      assert StringTools.truncate("0123456789abc", 10) == "0123456789..."
    end

    test "truncate/1 returns whole string without ..." do
      assert StringTools.truncate("0123456789abc", 100) == "0123456789abc"
    end
  end
end
