ExUnit.start()
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(Notesclub.Repo, :manual)
ExUnit.configure(exclude: :github_api)
