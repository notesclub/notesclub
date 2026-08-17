defmodule NotesclubWeb.NotebookLive.Show.Livemd do
  @moduledoc false

  import Phoenix.HTML

  alias Notesclub.Notebooks.Paths

  @doc """
  Renders markdown and highlights elixir code blocks
  """
  def render(content) do
    content
    |> Paths.remove_livemd_extension_from_links()
    |> mdex_to_html()
    |> HtmlSanitizeEx.markdown_html()
    |> highlight_code_blocks()
    |> raw()
  end

  defp mdex_to_html(content) do
    MDEx.to_html!(content,
      extension: [table: true, strikethrough: true, tasklist: true, autolink: true],
      render: [unsafe: true],
      syntax_highlight: nil
    )
  end

  defp highlight_code_blocks(html) do
    Regex.replace(
      ~r/<pre><code(?:\s+class="(?:language-)?([\w-]*)")?>([^<]*)<\/code><\/pre>/,
      html,
      &highlight_code_block(&1, &2, &3)
    )
  end

  defp highlight_code_block(_, "elixir", code) do
    code
    |> unescape_html()
    |> String.trim_trailing("\n")
    |> IO.iodata_to_binary()
    |> Makeup.highlight()
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
