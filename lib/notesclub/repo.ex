defmodule Notesclub.Repo do
  use Ecto.Repo,
    otp_app: :notesclub,
    adapter: Ecto.Adapters.Postgres
end
