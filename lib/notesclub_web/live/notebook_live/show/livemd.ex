defmodule NotesclubWeb.NotebookLive.Show.Livemd do
  @moduledoc false

  @doc """
  Renders markdown and highlights elixir code blocks
  """
  def render(content) do
    content
    |> HtmlSanitizeEx.markdown_html()
    |> Earmark.as_html!()
    |> highlight_code_blocks()
    |> Phoenix.HTML.raw()
  end

  defp highlight_code_blocks(html) do
    Regex.replace(
      ~r/<pre><code(?:\s+class="(\w*)")?>([^<]*)<\/code><\/pre>/,
      html,
      &highlight_code_block(&1, &2, &3)
    )
  end

  defp highlight_code_block(_, "elixir", code) do
    code
    |> unescape_html()
    |> IO.iodata_to_binary()
    |> Makeup.highlight()
  end

  defp highlight_code_block(_, "mermaid", code) do
    ~s(<pre><code class="mermaid">#{code}</code></pre>)
  end

  defp highlight_code_block(_, lang, code) do
    ~s(<pre><code class="makeup #{lang}">#{code}</code></pre>)
  end

  defp unescape_html(text) do
    text
    |> String.replace("&amp;", "&", global: true)
    |> String.replace("&lt;", "<", global: true)
    |> String.replace("&gt;", ">", global: true)
    |> String.replace("&quot;", "\"", global: true)
    |> String.replace("&#39;", "'", global: true)
  end
end
