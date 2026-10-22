# Notesclub · Discover Livebook Notebooks

We add new Livebook notebooks from Github every day.

https://notes.club

# Get involved

Welcome to Notesclub!

Feel free to:
- [Take an issue](https://github.com/notesclub/notesclub/issues)
- Propose a new issue
- Refactor existent code
- Add documentation
Thanks!

# Run it locally

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start the Postgres database with `docker-compose up`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Quality checks

Install Elixir dependencies with `mix deps.get`, install JavaScript dependencies
with `npm ci --prefix assets` (Node.js 24), and start PostgreSQL before running:

* `mix check` formats the code, compiles with warnings treated as errors, builds
  CSS and JavaScript, runs strict Credo checks and tests, and scans with Sobelow.
* `mix precommit` also audits dependencies, checks for unused dependencies, checks
  formatting without rewriting files, and runs tests with coverage. Coverage uses
  Mix's default 90% minimum; HTML reports are written to `cover/`.
* `mix ci` runs `mix precommit`. GitHub Actions uses this command and then runs
  the existing Dialyzer checks.

All three commands default to the test environment and return a nonzero status
when checks fail. Asset builds write to `priv/static/assets/`; the build tools
download their binaries on first use. Sobelow fails on findings at any confidence level and runs
without its update check. Tests tagged `:github_api` remain excluded; run them
explicitly with `mix test --include github_api` after configuring the key below.

## Secrets

To use tests with the `:github_api` tag, and to interact with the GitHub API the project requires a [GitHub API key](https://github.com/settings/tokens/new).
Create a `config/test_secrets.exs` template file.

Replace **GITHUB_API_KEY** with a GitHub API Key.

```elixir
# Create a secret.exs file with the following content.
# Replace GITHUB_API_KEY with your github api key.
import Config

config :notesclub, :github_api_key, "GITHUB_API_KEY"
```

To use GitHub API in development, create a similar `config/dev_secrets.exs`

`seeds.exs` already imports some example notebooks so you don't need to download notebooks from GitHub for most things.

Yet, to download new notebooks you can set `GITHUB_API_KEY` as explained above and run:

```elixir
%{page: 1}
|> Notesclub.Workers.RecentNotebooksWorker.new()
|> Oban.insert()
```

And to reload all notebooks already present in your db:
```elixir
%{}
|> Notesclub.Workers.AllUserNotebooksSyncWorker.new()
|> Oban.insert()
```

### Sign in with Github functionality

To set up this functionality during development, follow these steps to create a GitHub OAuth application:

1. **Log in to GitHub**: Sign in to your GitHub account.

2. **Navigate to Settings**: Click on your profile picture in the top right corner, then select "Settings."

3. **Access Developer Settings**: Scroll down to the bottom of the left sidebar and click on "Developer settings."

4. **Create an OAuth App**: Under "OAuth Apps," click on "New OAuth App."

5. **Fill in Details**:
   - **Application Name**: Provide a descriptive name for your app.
   - **Homepage URL**: Enter the URL where users can learn more about your app.
   - **Authorization callback URL**: This is the URL where GitHub will redirect users after they authorize your app. For local development, you can use `http://localhost:YOUR_PORT/auth/github/callback`.

6. **Generate Client ID and Client Secret**:
   - Once you've filled in the details, click "Register application."
   - You'll receive a **Client ID** and a **Client Secret**. These are essential for authenticating with GitHub.

7. **Replace Variables in Your Code**:
   - Create a `config/dev_secrets.exs` file and replace `GITHUB_OAUTH_CLIENT_ID` and `GITHUB_OAUTH_CLIENT_SECRET` with the actual values you received from GitHub:

  ```elixir
  # Create a dev_secrets.exs file with the following content.
  # Replace GITHUB_API_KEY with your github api key.
  import Config

  config :ueberauth, Ueberauth.Strategy.Github.OAuth,
    client_id: "GITHUB_OAUTH_CLIENT_ID",
    client_secret: "GITHUB_OAUTH_CLIENT_SECRET"
  ```

# Powered by
Powered by [AppSignal](https://www.appsignal.com) and [Oban Pro](https://getoban.pro)
