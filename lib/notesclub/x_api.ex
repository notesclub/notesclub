defmodule Notesclub.XAPI do
  @moduledoc """
  Post messages using the X API V2.
  """

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
    access_token =
      generate_access_token_url(
        auth_code,
        Application.get_env(:notesclub, :x_client_id),
        Application.get_env(:notesclub, :x_callback_url)
      )
      |> fetch_token()

      post(message, access_token)
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

  defp fetch_token(url) do
    {:ok, response} =
      Req.post(
        url,
        headers: [
          Content_Type: ["application/x-www-form-urlencoded"],
          Authorization: generate_auth_header()
        ]
      )

    response.body["access_token"]
  end

  defp generate_auth_header do
    client_id = Application.get_env(:notesclub, :x_client_id)
    secret = Application.get_env(:notesclub, :x_client_secret)

    "Basic " <> Base.encode64(client_id <> ":" <> secret)
  end

  defp post(text, access_token) do
    {:ok, _response} =
      Req.post(
        "https://api.twitter.com/2/tweets",
        json: %{text: text},
        headers: [
          Authorization: "Bearer " <> access_token
        ],
        body: "json"
      )
  end
end
