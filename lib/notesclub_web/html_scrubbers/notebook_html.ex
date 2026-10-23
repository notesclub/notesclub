defmodule NotesclubWeb.HTMLScrubbers.NotebookHTML do
  @moduledoc false

  use HtmlSanitizeEx, extend: :markdown_html

  # Makeup emits these classes for syntax highlighting. Keeping them in the
  # sanitizer lets the entire rendered document be scrubbed after highlighting.
  allow_tag_with_these_attributes("pre", ["class"])
  allow_tag_with_these_attributes("span", ["class"])
end
