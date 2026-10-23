defmodule Notesclub.Repo.Migrations.EncryptXTokens do
  use Ecto.Migration

  alias Notesclub.TokenCipher

  def up do
    %{rows: rows} = repo().query!("SELECT id, access_token, refresh_token FROM x_tokens")

    Enum.each(rows, fn [id, access_token, refresh_token] ->
      repo().query!(
        "UPDATE x_tokens SET access_token = $1, refresh_token = $2 WHERE id = $3",
        [TokenCipher.encrypt(access_token), encrypt_optional(refresh_token), id]
      )
    end)
  end

  def down do
    %{rows: rows} = repo().query!("SELECT id, access_token, refresh_token FROM x_tokens")

    Enum.each(rows, fn [id, access_token, refresh_token] ->
      repo().query!(
        "UPDATE x_tokens SET access_token = $1, refresh_token = $2 WHERE id = $3",
        [decrypt!(access_token), decrypt_optional!(refresh_token), id]
      )
    end)
  end

  defp encrypt_optional(nil), do: nil
  defp encrypt_optional(value), do: TokenCipher.encrypt(value)

  defp decrypt_optional!(nil), do: nil
  defp decrypt_optional!(value), do: decrypt!(value)

  defp decrypt!(value) do
    case TokenCipher.decrypt(value) do
      {:ok, decrypted} -> decrypted
      :error -> raise "could not decrypt an X token"
    end
  end
end
