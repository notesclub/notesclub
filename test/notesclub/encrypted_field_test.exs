defmodule Notesclub.EncryptedFieldTest do
  use ExUnit.Case, async: true

  alias Notesclub.EncryptedField
  alias Notesclub.TokenCipher

  test "casts only nullable binary values" do
    assert EncryptedField.cast(nil) == {:ok, nil}
    assert EncryptedField.cast("token") == {:ok, "token"}
    assert EncryptedField.cast(123) == :error
  end

  test "dumps ciphertext and loads plaintext" do
    assert EncryptedField.dump(nil) == {:ok, nil}
    assert EncryptedField.dump(123) == :error
    assert EncryptedField.load(nil) == {:ok, nil}
    assert EncryptedField.load(123) == :error
    assert EncryptedField.load("legacy plaintext") == {:ok, "legacy plaintext"}

    assert {:ok, encrypted} = EncryptedField.dump("secret token")
    assert String.starts_with?(encrypted, "XCP.")
    refute encrypted =~ "secret token"
    assert EncryptedField.load(encrypted) == {:ok, "secret token"}
  end

  test "ciphertext is authenticated and already-encrypted values are unchanged" do
    encrypted = TokenCipher.encrypt("secret token")
    assert TokenCipher.encrypt(encrypted) == encrypted
    assert TokenCipher.decrypt("legacy plaintext") == {:ok, "legacy plaintext"}

    "XCP." <> encoded_payload = encrypted
    <<first_byte, rest::binary>> = Base.url_decode64!(encoded_payload, padding: false)

    tampered =
      "XCP." <>
        Base.url_encode64(<<Bitwise.bxor(first_byte, 1), rest::binary>>, padding: false)

    assert TokenCipher.decrypt(tampered) == :error
    assert EncryptedField.load(tampered) == :error
  end
end
