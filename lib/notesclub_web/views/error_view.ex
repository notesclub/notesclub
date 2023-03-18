defmodule NotesclubWeb.ErrorView do
  use NotesclubWeb, :view

  def render("404.html", assigns) do
    Phoenix.View.render_layout NotesclubWeb.LayoutView, "root.html", assigns do
      render("404_not_found.html", assigns)
    end
  end

  def render("500.html", assigns) do
    Phoenix.View.render_layout NotesclubWeb.LayoutView, "root.html", assigns do
      render("500_internal_error.html", assigns)
    end
  end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
