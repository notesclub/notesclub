defmodule NotesclubWeb.UserAuth do
  @moduledoc """
  A plug for retrieving current user data.
  """

  import Plug.Conn

  alias Notesclub.Accounts
  alias NotesclubWeb.RateLimiter

  @live_event_limit 60
  @live_event_period :timer.minutes(1)

  @doc """
  Handles mounting and retrieving the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_id, or nil if
      there's no user_id or no matching user.
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    socket = mount_current_user(socket, session)
    socket = Phoenix.Component.assign(socket, :rate_limit_identity, live_client_identity(socket))

    {:cont,
     Phoenix.LiveView.attach_hook(
       socket,
       :rate_limit_events,
       :handle_event,
       &rate_limit_event/3
     )}
  end

  @doc """
  Retrieves current user information and assigns it to the connection.
  """
  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id == nil do
      assign(conn, :current_user, nil)
    else
      assign(conn, :current_user, Accounts.get_user(user_id))
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_id = session["user_id"] do
        Accounts.get_user(user_id)
      end
    end)
  end

  defp rate_limit_event(event, _params, socket) do
    key = {:live_event, socket.assigns.rate_limit_identity, event}

    if RateLimiter.allow?(key, @live_event_limit, @live_event_period) do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.put_flash(socket, :error, "Too many requests. Please slow down.")}
    end
  end

  defp live_client_identity(%{assigns: %{current_user: %{id: id}}}), do: {:user, id}

  defp live_client_identity(socket) do
    case Phoenix.LiveView.get_connect_info(socket, :peer_data) do
      %{address: address} -> {:ip, address}
      _unavailable -> {:socket, socket.id}
    end
  end
end
