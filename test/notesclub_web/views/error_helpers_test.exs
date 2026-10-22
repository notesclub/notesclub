defmodule NotesclubWeb.ErrorHelpersTest do
  use ExUnit.Case, async: true

  alias NotesclubWeb.ErrorHelpers
  alias NotesclubWeb.ErrorView

  test "renders escaped validation feedback linked to the form field" do
    form = %Phoenix.HTML.Form{name: "notebook", errors: [title: {"can't be blank", []}]}
    [tag] = ErrorHelpers.error_tag(form, :title)
    html = Phoenix.HTML.safe_to_string(tag)
    assert html =~ "invalid-feedback"
    assert html =~ "phx-feedback-for=\"notebook[title]\""
    assert html =~ "can&#39;t be blank"
    assert ErrorHelpers.error_tag(form, :content) == []
  end

  test "interpolates plural validation messages and unknown error pages" do
    assert ErrorHelpers.translate_error({"should be at least %{count} character(s)", count: 2}) ==
             "should be at least 2 character(s)"

    assert ErrorView.template_not_found("403.html", %{}) == "Forbidden"
  end
end
