defmodule Notesclub.X.XAPI do
  @moduledoc """
  X API V2
  """

  def generate_authorize_url(client_id, callback_url) do
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

  def fetch_token(code, client_id, callback_url) do
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

  def post(text, access_token) do
    case Req.post(
           "https://api.twitter.com/2/tweets",
           json: %{text: text},
           headers: [
             Authorization: "Bearer " <> access_token
           ],
           body: "json"
         ) do
      {:ok, %Req.Response{status: 201} = response} ->
        {:ok, response}

      {:ok, response} ->
        {:error, response}

      error ->
        {:error, error}
    end
  end
end
