defmodule NotesclubWeb.HTMLScrubbers.NotebookHTML do
  @moduledoc false

  use HtmlSanitizeEx, extend: :strip_tags

  @trusted_image_hosts ~w(
    avatars.githubusercontent.com
    github.com
    private-user-images.githubusercontent.com
    raw.githubusercontent.com
    user-images.githubusercontent.com
  )

  allow_tag_with_uri_attributes("a", ["href"], ["http", "https", "mailto"])
  allow_tag_with_these_attributes("a", ["name", "title"])
  allow_tag_with_this_attribute_values("a", "target", ["_blank"])
  allow_tag_with_this_attribute_values("a", "rel", ["noopener", "noreferrer"])

  for tag <-
        ~w(b blockquote br del em h1 h2 h3 h4 h5 h6 hr i li ol p strong table tbody td th thead tr u ul) do
    allow_tag_with_these_attributes(tag, [])
  end

  allow_tag_with_these_attributes("code", ["class"])
  allow_tag_with_these_attributes("img", ["width", "height", "title", "alt"])

  # Makeup emits these classes for syntax highlighting. Keeping them in the
  # sanitizer lets the entire rendered document be scrubbed after highlighting.
  allow_tag_with_these_attributes("pre", ["class"])
  allow_tag_with_these_attributes("span", ["class"])

  def scrub_attribute("img", {"src", value}) do
    case URI.parse(value) do
      %URI{scheme: scheme, host: host}
      when scheme in ["http", "https"] and host in @trusted_image_hosts ->
        {"src", value}

      _untrusted ->
        nil
    end
  end
end
