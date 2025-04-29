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
    <.link
      href={"https://twitter.com/intent/tweet?text=#{@share_to_x_text}"}
      target="blank_"
      class="group relative inline-block"
      aria-label="Share to X"
    >
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
      <span class="
        absolute top-full left-1/2 -translate-x-1/2 mt-2 px-2 py-1 
        text-xs font-medium text-white bg-gray-800 rounded
        opacity-0 group-hover:opacity-100 transition-opacity
        pointer-events-none whitespace-nowrap
      ">
        Share to X 
      </span>
    </.link>
    """
  end

  attr :share_to_bluesky_text, :string, required: true
  # attr :url, :string, required: true

  @doc """
  Share to Bluesky icon
  """
  def share_to_bluesky(assigns) do
    ~H"""
    <.link
      href={"https://bsky.app/intent/compose?text=#{@share_to_bluesky_text}"}
      target="_blank"
      class="group relative inline-block"
      aria-label="Share to Bluesky"
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="35" height="35" viewBox="0 0 512 512">
        <circle cx="256" cy="256" r="256" fill="currentColor"></circle>
        <path
          d="m175.29 177.44c36.56 27.46 75.91 83.11 90.35 113.00 14.44-29.89 53.77-85.53 90.35-113.00 26.39-19.81 69.14-35.14 69.14 13.63 0 9.74-5.59 81.83-8.86 93.53-11.39 40.69-52.87 51.06-89.77 44.78 64.50 10.98 80.91 47.34 45.47 83.71-67.31 69.07-96.74-17.33-104.28-39.47-1.38-4.06-2.03-5.96-2.04-4.34-0.01-1.62-0.66 0.28-2.04 4.34-7.55 22.13-36.98 108.52-104.28 39.47-35.44-36.37-19.03-72.73 45.47-83.71-36.90 6.28-78.38-4.09-89.77-44.78-3.28-11.70-8.86-83.79-8.86-93.53 0-48.77 42.74-33.44 69.14-13.63z"
          fill="white"
          transform="translate(-10, -30)"
        />
      </svg>
      <span class="
        absolute top-full left-1/2 -translate-x-1/2 mt-2 px-2 py-1 
        text-xs font-medium text-white bg-gray-800 rounded
        opacity-0 group-hover:opacity-100 transition-opacity
        pointer-events-none whitespace-nowrap
      ">
        Share to Bluesky
      </span>
    </.link>
    """
  end
end
