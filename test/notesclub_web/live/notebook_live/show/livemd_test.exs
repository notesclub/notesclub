defmodule NotesclubWeb.NotebookLive.Show.LivemdTest do
  use Notesclub.DataCase

  alias NotesclubWeb.NotebookLive.Show.Livemd

  test "render/1 renders markdown, adds highlight class and highlights elixir code" do
    code = """
    # Test

    ```elixir
    1+1
    ```
    """

    assert Livemd.render(code) ==
             {:safe,
              "<h1>\nTest</h1>\n<pre class=\"highlight\"><code><span class=\"mi\">1</span><span class=\"o\">+</span><span class=\"mi\">1</span></code></pre>\n"}
  end

  test "render/1 removes javascript to prevent XSS" do
    assert Livemd.render("<script>alert('hi')</script>") == {:safe, "<p>\nalert(‘hi’)</p>\n"}
    assert Livemd.render("<a href=\"javascript:alert('hi');\">hey</a>") == {:safe, "<a>hey</a>"}
  end

  # DockYard-Academy has many notebooks with navigation links at the bottom
  # Example: https://notes.club/DockYard-Academy/curriculum/exercises/timer
  test "render/1 removes local .livemd links" do
    assert Livemd.render("[Score Tracker](../exercises/score_tracker.livemd)") ==
             {:safe, "<p>\n<a href=\"../exercises/score_tracker\">Score Tracker</a></p>\n"}
  end

  test "render/1 does NOT change mermaid code blocks" do
    code = """
    ```mermaid
    whatever
    ```
    """

    assert Livemd.render(code) ==
             {:safe, "<pre><code class=\"mermaid\">whatever</code></pre>\n"}
  end
end
