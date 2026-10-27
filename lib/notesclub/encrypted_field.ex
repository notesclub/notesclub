defmodule Notesclub.EncryptedField do
  @moduledoc false

  use Ecto.Type

  alias Notesclub.TokenCipher

  @type t :: String.t()

  def type, do: :string

  def cast(nil), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, value}
  def cast(_value), do: :error

  def dump(nil), do: {:ok, nil}
  def dump(value) when is_binary(value), do: {:ok, TokenCipher.encrypt(value)}
  def dump(_value), do: :error

  def load(nil), do: {:ok, nil}
  def load("XCP." <> _rest = value), do: TokenCipher.decrypt(value)

  # Kept temporarily for safe rolling deploys; the migration encrypts all
  # existing rows, while old application instances may still write plaintext.
  def load(value) when is_binary(value), do: {:ok, value}
  def load(_value), do: :error
end
