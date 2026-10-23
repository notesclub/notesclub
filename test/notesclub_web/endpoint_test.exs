defmodule NotesclubWeb.EndpointTest do
  use ExUnit.Case, async: true

  alias NotesclubWeb.Endpoint

  test "session cookies are encrypted with explicit security flags" do
    options = Endpoint.session_options()

    assert is_binary(options[:encryption_salt])
    assert options[:http_only]
    assert options[:same_site] == "Lax"
    assert options[:secure] == (Mix.env() == :prod)
  end
end
