ExUnit.start()
Faker.start()

Application.put_env(
  :notesclub,
  :notebook_analyser_implementation,
  Notesclub.Notebooks.Analyser.FakeAnalyser
)

Ecto.Adapters.SQL.Sandbox.mode(Notesclub.Repo, :manual)
ExUnit.configure(exclude: :github_api)
