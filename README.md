# Notesclub · Discover Livebook Notebooks

Every day we add new Livebook notebooks from Github.

https://notes.club

# Get involved

Welcome to Notesclub!

Feel free to:
- [Take an issue](https://github.com/notesclub/notesclub/issues)
- Propose a new one issue
- Refactor existent code
- Add documentation
Thanks!

# Run it locally

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Secrets

To use tests with the `:github_api` tag, and to interact with the GitHub API key the project requires a GitHub API key.
Create a `config/test_secrets.exs` template file.

Replace **GITHUB_API_KEY** with a GitHub API Key.

```elixir
# Create a secret.exs file with the following content.
# Replace GITHUB_API_KEY with your github api key.
import Config

config :notesclub, :github_api_key, "GITHUB_API_KEY"

```

To download notebooks in development, create a similar `config/dev.secrets.exs`

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
