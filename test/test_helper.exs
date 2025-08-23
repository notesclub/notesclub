ExUnit.start()
Faker.start()

Application.put_env(
  :notesclub,
  :notebook_rater_implementation,
  Notesclub.Notebooks.Rater.FakeRater
)

Ecto.Adapters.SQL.Sandbox.mode(Notesclub.Repo, :manual)
ExUnit.configure(exclude: :github_api)
