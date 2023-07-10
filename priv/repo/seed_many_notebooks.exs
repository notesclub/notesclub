# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seed_many_notebooks.exs

alias Notesclub.Accounts
alias Notesclub.Notebooks
alias Notesclub.Repos

content = """
# Dummy content

```elixir
1+1
```
"""

{:ok, user} =
  Accounts.create_user(%{
    username: "livebook-dev",
    avatar_url: "https://avatars.githubusercontent.com/u/87464290?v=4"
  })

{:ok, repo} =
  Repos.create_repo(%{
    name: "livebook",
    full_name: "livebook-dev/livebook",
    default_branch: "main",
    fork: false,
    user_id: user.id
  })

Enum.each(1..100, fn i ->
  {:ok, _} =
    Notebooks.create_notebook(%{
      user_id: user.id,
      repo_id: repo.id,
      github_owner_login: "Test Owner Login With A Very Long Name",
      github_repo_name: "Test Repo Name With A Very Long Name",
      github_filename: "example-#{i}.livemd",
      github_html_url: "https://github.com/livebook-dev/livebook/blob/main/lib/livebook/notebook/explore/#{i}.livemd",
      url: "https://github.com/livebook-dev/livebook/blob/main/lib/livebook/notebook/explore/#{i}.livemd",
      github_owner_avatar_url: "https://avatars.githubusercontent.com/u/59829569?v=4",
      content: content
    })
end)
