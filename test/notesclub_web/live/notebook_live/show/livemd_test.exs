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
              "<h1>Test</h1>\n<pre class=\"highlight\"><code><span class=\"mi\">1</span><span class=\"o\">+</span><span class=\"mi\">1</span></code></pre>"}
  end

  test "render/1 removes javascript to prevent XSS" do
    {:safe, script_html} = Livemd.render("<script>alert('hi')</script>")
    refute script_html =~ "<script"
    refute script_html =~ "</script>"

    assert Livemd.render("<a href=\"javascript:alert('hi');\">hey</a>") ==
             {:safe, "<p><a>hey</a></p>"}
  end

  test "render/1 does not activate encoded HTML" do
    {:safe, html} = Livemd.render("&lt;img src=x onerror=alert(1)&gt;")

    refute html =~ "<img"
    assert html =~ "&lt;img"
  end

  test "render/1 keeps HTML in code blocks escaped" do
    {:safe, html} =
      Livemd.render("""
      ```text
      <img src=x onerror=alert(1)>
      ```
      """)

    refute html =~ "<img"
    assert html =~ "&lt;img"
  end

  # DockYard-Academy has many notebooks with navigation links at the bottom
  # Example: https://notes.club/DockYard-Academy/curriculum/exercises/timer
  test "render/1 removes local .livemd links" do
    assert Livemd.render("[Score Tracker](../exercises/score_tracker.livemd)") ==
             {:safe, "<p><a href=\"../exercises/score_tracker\">Score Tracker</a></p>"}
  end

  test "render/1 does NOT change mermaid code blocks" do
    code = """
    ```mermaid
    whatever
    ```
    """

    assert Livemd.render(code) ==
             {:safe, "<pre><code class=\"makeup mermaid\">whatever\n</code></pre>"}
  end
end
