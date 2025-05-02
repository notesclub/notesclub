defmodule Notesclub.X do
  @moduledoc """
  Post messages using the X API V2.
  """

  alias Notesclub.X.XAPI
  alias Notesclub.X.XTokens

  def get_authorize_url do
    XAPI.generate_authorize_url(
      Application.get_env(:notesclub, :x_client_id),
      Application.get_env(:notesclub, :x_callback_url)
    )
  end

  @doc """
  Authenticates with X API using auth code and stores the token.
  Returns {:ok, access_token} or {:error, reason}
  """
  def authenticate(auth_code) do
    client_id = Application.get_env(:notesclub, :x_client_id)
    callback_url = Application.get_env(:notesclub, :x_callback_url)

    with {:ok, access_token, refresh_token} <-
           XAPI.fetch_token(auth_code, client_id, callback_url),
         {:ok, _token} <-
           XTokens.create_token(%{
             access_token: access_token,
             refresh_token: refresh_token
           }) do
      {:ok, access_token}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Post a message using a stored token or fetches the latest token.
  Automatically refreshes the token if needed.
  """
  def post(message) do
    case XTokens.get_latest_token() do
      nil ->
        {:error, :no_token_available}

      token ->
        # Try posting with the current token
        case XAPI.post(message, token.access_token) do
          {:ok, response} ->
            # If successful, mark token as used and return response
            XTokens.mark_token_used(token)
            {:ok, response}

          {:error, _reason} ->
            refresh_token_and_post(message, token)
        end
    end
  end

  defp refresh_token_and_post(_, %{refresh_token: nil}) do
    {:error, :no_refresh_token}
  end

  defp refresh_token_and_post(message, token) do
    case XAPI.refresh_access_token(token.refresh_token) do
      {:ok, new_access_token, new_refresh_token} ->
        # Update token in database
        {:ok, updated_token} =
          XTokens.update_token(token, %{
            access_token: new_access_token,
            refresh_token: new_refresh_token
          })

        XAPI.post(message, updated_token.access_token)

      error ->
        error
    end
  end
end
