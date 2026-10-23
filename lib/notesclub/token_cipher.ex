defmodule Notesclub.TokenCipher do
  @moduledoc false

  alias Plug.Crypto.KeyGenerator
  alias Plug.Crypto.MessageEncryptor

  @aad "notesclub:x-token:v1"
  @key_salt "notesclub x token encryption"

  def encrypt("XCP." <> _rest = encrypted), do: encrypted

  def encrypt(value) when is_binary(value) do
    MessageEncryptor.encrypt(value, @aad, encryption_key(), "")
  end

  def decrypt("XCP." <> _rest = encrypted) do
    MessageEncryptor.decrypt(encrypted, @aad, encryption_key(), "")
  end

  def decrypt(value) when is_binary(value), do: {:ok, value}

  defp encryption_key do
    secret =
      Application.get_env(:notesclub, :x_token_encryption_key) ||
        endpoint_secret_key_base()

    KeyGenerator.generate(secret, @key_salt, length: 32)
  end

  defp endpoint_secret_key_base do
    :notesclub
    |> Application.fetch_env!(NotesclubWeb.Endpoint)
    |> Keyword.fetch!(:secret_key_base)
  end
end
