defmodule Notesclub.XAPI do
  @moduledoc """
  Post messages using the X API V2.
  """

  alias Notesclub.XToken

  def get_authorize_url() do
    generate_authorize_url(
      Application.get_env(:notesclub, :x_client_id),
      Application.get_env(:notesclub, :x_callback_url)
    )
  end

  defp generate_authorize_url(client_id, callback_url) do
    query_params = %{
      client_id: client_id,
      response_type: "code",
      scope: "tweet.read+users.read+tweet.write+offline.access",
      code_challenge: "challenge",
      code_challenge_method: "plain",
      state: "state",
      redirect_uri: callback_url
    }

    "https://twitter.com/i/oauth2/authorize?#{URI.encode_query(query_params)}"
  end

  def authenticate_and_post(auth_code, message) do
    case authenticate(auth_code) do
      {:ok, access_token} -> post(message, access_token)
      error -> error
    end
  end

  @doc """
  Authenticates with X API using auth code and stores the token.
  Returns {:ok, access_token} or {:error, reason}
  """
  def authenticate(auth_code) do
    client_id = Application.get_env(:notesclub, :x_client_id)
    callback_url = Application.get_env(:notesclub, :x_callback_url)

    with {:ok, access_token, refresh_token} <- fetch_token(auth_code, client_id, callback_url),
         {:ok, _token} <-
           XToken.create_token(%{
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
  def post_with_stored_token(message) do
    case XToken.get_latest_token() do
      nil ->
        {:error, :no_token_available}

      token ->
        # Try posting with the current token
        case post(message, token.access_token) do
          {:ok, response} ->
            # If successful, mark token as used and return response
            XToken.mark_token_used(token)
            {:ok, response}

          {:error, _reason} ->
            # If error occurs, try refreshing the token and post again
            if token.refresh_token do
              case refresh_access_token(token.refresh_token) do
                {:ok, new_access_token, new_refresh_token} ->
                  # Update token in database
                  {:ok, updated_token} =
                    XToken.create_token(%{
                      access_token: new_access_token,
                      refresh_token: new_refresh_token
                    })

                  post(message, updated_token.access_token)

                error ->
                  error
              end
            else
              {:error, :no_refresh_token}
            end
        end
    end
  end

  @doc """
  Refreshes an access token using the refresh token.
  Returns {:ok, new_access_token, new_refresh_token} or {:error, reason}
  """
  def refresh_access_token(refresh_token) do
    client_id = Application.get_env(:notesclub, :x_client_id)

    refresh_token_url = "https://api.twitter.com/2/oauth2/token"

    body =
      URI.encode_query(%{
        "refresh_token" => refresh_token,
        "grant_type" => "refresh_token",
        "client_id" => client_id
      })

    case Req.post(
           refresh_token_url,
           body: body,
           headers: [
             {"Content-Type", "application/x-www-form-urlencoded"},
             {"Authorization", generate_auth_header()}
           ]
         ) do
      {:ok, response} ->
        access_token = response.body["access_token"]
        new_refresh_token = response.body["refresh_token"]
        {:ok, access_token, new_refresh_token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_token(code, client_id, callback_url) do
    url = generate_access_token_url(code, client_id, callback_url)

    case Req.post(
           url,
           headers: [
             Content_Type: ["application/x-www-form-urlencoded"],
             Authorization: generate_auth_header()
           ]
         ) do
      {:ok, response} ->
        access_token = response.body["access_token"]
        refresh_token = response.body["refresh_token"]
        {:ok, access_token, refresh_token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp generate_access_token_url(code, client_id, callback_url) do
    query_params = %{
      "code" => code,
      "grant_type" => "authorization_code",
      "client_id" => client_id,
      "redirect_uri" => callback_url,
      "code_verifier" => "challenge"
    }

    "https://api.twitter.com/2/oauth2/token?#{URI.encode_query(query_params)}"
  end

  defp generate_auth_header do
    client_id = Application.get_env(:notesclub, :x_client_id)
    secret = Application.get_env(:notesclub, :x_client_secret)

    "Basic " <> Base.encode64(client_id <> ":" <> secret)
  end

  defp post(text, access_token) do
    IO.inspect("Posting message: #{text}")

    case Req.post(
           "https://api.twitter.com/2/tweets",
           json: %{text: text},
           headers: [
             Authorization: "Bearer " <> access_token
           ],
           body: "json"
         ) do
      {:ok, %Req.Response{status: 201} = response} ->
        IO.inspect("Response: #{inspect(response)}")
        {:ok, response}

      {:ok, response} ->
        IO.inspect("Error: #{inspect(response)}")
        {:error, response}

      error ->
        IO.inspect("Error: #{inspect(error)}")
        {:error, error}
    end
  end
end
