defmodule NotesclubWeb.NotebookLive.ShareComponent do
  @moduledoc """
  Icon to share to X/Twitter
  """
  use Phoenix.Component

  attr :share_to_x_text, :string, required: true

  @doc """
  Share to X/Twitter icon
  """
  def share_to_x(assigns) do
    ~H"""
    <.link href={"https://twitter.com/intent/tweet?text=#{@share_to_x_text}"} target="blank_">
      <svg xmlns="http://www.w3.org/2000/svg" width="35" height="35" viewBox="0 0 512 512">
        <circle cx="256" cy="256" r="256" fill="currentColor"></circle>
        <g transform="scale(0.5) translate(256 256)">
          <path
            d="M389.2 48h70.6L305.6 224.2 487 464H345L233.7 318.6 106.5 464H35.8L200.7 275.5 26.8 48H172.4L272.9 180.9 389.2 48zM364.4 421.8h39.1L151.1 88h-42L364.4 421.8z"
            fill="white"
          >
          </path>
        </g>
      </svg>
    </.link>
    """
  end
end
