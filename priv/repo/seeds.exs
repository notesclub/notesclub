# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias Notesclub.Notebooks
alias Notesclub.Accounts
alias Notesclub.Repos

content = """
# Dummy content

```elixir
Mix.install([
  {:req, "~> 0.3.11"},
  {:jason, "~> 1.4"}
])
```
...
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

{:ok, _} =
  Notebooks.create_notebook(%{
    content: content,
    github_owner_login: "livebook-dev",
    github_repo_name: "livebook",
    github_filename: "intro_to_maplibre.livemd",
    github_html_url:
      "https://github.com/livebook-dev/livebook/blob/e5a02ac97e96a0a5c371aafedad76a59a152ece5/lib/livebook/notebook/explore/intro_to_maplibre.livemd",
    github_owner_avatar_url: "https://avatars.githubusercontent.com/u/87464290?v=4",
    user_id: user.id,
    repo_id: repo.id,
    url:
      "https://github.com/livebook-dev/livebook/blob/main/lib/livebook/notebook/explore/intro_to_maplibre.livemd"
  })

{:ok, user} =
  Accounts.create_user(%{
    username: "DockYard-Academy",
    avatar_url: "https://avatars.githubusercontent.com/u/100445774?v=4"
  })

{:ok, repo} =
  Repos.create_repo(%{
    name: "beta_curriculum",
    full_name: "DockYard-Academy/beta_curriculum",
    default_branch: "main",
    fork: false,
    user_id: user.id
  })

{:ok, _} =
  Notebooks.create_notebook(%{
    content: content,
    github_owner_login: "DockYard-Academy",
    github_repo_name: "beta_curriculum",
    github_filename: "ranges.livemd",
    github_html_url:
      "https://github.com/DockYard-Academy/beta_curriculum/blob/dbeb07eaea47140c6b8bde868bde76e88121a7d7/reading/ranges.livemd",
    github_owner_avatar_url: "https://avatars.githubusercontent.com/u/100445774?v=4",
    user_id: user.id,
    repo_id: repo.id,
    url: "https://github.com/DockYard-Academy/beta_curriculum/blob/main/reading/ranges.livemd"
  })

{:ok, user} =
  Accounts.create_user(%{
    username: "podium",
    avatar_url: "https://avatars.githubusercontent.com/u/7001675?v=4"
  })

{:ok, repo} =
  Repos.create_repo(%{
    name: "elixir-secure-coding",
    full_name: "podium/elixir-secure-coding",
    default_branch: "main",
    fork: false,
    user_id: user.id
  })

{:ok, _} =
  Notebooks.create_notebook(%{
    content: content,
    github_owner_login: "podium",
    github_repo_name: "elixir-secure-coding",
    github_filename: "7-anti-patterns.livemd",
    github_html_url:
      "https://github.com/podium/elixir-secure-coding/blob/ce52829b277f40b8d398d1d5ac1bd6b5c632800c/modules/7-anti-patterns.livemd",
    github_owner_avatar_url: "https://avatars.githubusercontent.com/u/7001675?v=4",
    user_id: user.id,
    repo_id: repo.id,
    url: "https://github.com/podium/elixir-secure-coding/blob/main/modules/7-anti-patterns.livemd"
  })

{:ok, user} =
  Accounts.create_user(%{
    username: "elixir-nx",
    avatar_url: "https://avatars.githubusercontent.com/u/74903619?v=4"
  })

{:ok, repo} =
  Repos.create_repo(%{
    name: "axon",
    full_name: "elixir-nx/axon",
    default_branch: "main",
    fork: false,
    user_id: user.id
  })

{:ok, _} =
  Notebooks.create_notebook(%{
    content: content,
    github_owner_login: "elixir-nx",
    github_repo_name: "axon",
    github_filename: "mnist.livemd",
    github_html_url:
      "https://github.com/elixir-nx/axon/blob/7f1d1ab2e6c8a35edf3f58eae9182c4a149cd8d5/notebooks/vision/mnist.livemd",
    github_owner_avatar_url: "https://avatars.githubusercontent.com/u/74903619?v=4",
    user_id: user.id,
    repo_id: repo.id,
    url: "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd"
  })

{:ok, user} =
  Accounts.create_user(%{
    username: "BrooklinJazz",
    avatar_url: "https://avatars.githubusercontent.com/u/14877564?v=4"
  })

{:ok, repo} =
  Repos.create_repo(%{
    name: "talks",
    full_name: "BrooklinJazz/talks",
    default_branch: "main",
    fork: false,
    user_id: user.id
  })

{:ok, _} =
  Notebooks.create_notebook(%{
    content: content,
    github_owner_login: "BrooklinJazz",
    github_repo_name: "talks",
    github_filename: "ets.livemd",
    github_html_url:
      "https://github.com/BrooklinJazz/talks/blob/6f4985a221ed0eeab438c0d0b3e9fe16934227c9/livebook-with-otp/ets.livemd",
    github_owner_avatar_url: "https://avatars.githubusercontent.com/u/14877564?v=4",
    user_id: user.id,
    repo_id: repo.id,
    url: "https://github.com/BrooklinJazz/talks/blob/main/livebook-with-otp/ets.livemd"
  })

{:ok, user} =
  Accounts.create_user(%{
    username: "hectorperez",
    avatar_url: "https://avatars.githubusercontent.com/u/9378?v=4"
  })

{:ok, repo} =
  Repos.create_repo(%{
    name: "livebook-notebooks.livemd",
    full_name: "hectorperez/livebook-notebooks",
    default_branch: "main",
    fork: false,
    user_id: user.id
  })

{:ok, _} =
  Notebooks.create_notebook(%{
    content: content,
    github_owner_login: "hectorperez",
    github_repo_name: "livebook-notebooks",
    github_filename: "chat_with_openai_and_kino.livemd",
    github_html_url:
      "https://github.com/hectorperez/livebook-notebooks/blob/e8eb7d08d984a306beae32477bc009ccf0b5f3e7/notebooks/chat_with_openai_and_kino.livemd",
    github_owner_avatar_url: "https://avatars.githubusercontent.com/u/9378?v=4",
    user_id: user.id,
    repo_id: repo.id,
    url:
      "https://github.com/hectorperez/livebook-notebooks/blob/main/notebooks/chat_with_openai_and_kino.livemd"
  })

{:ok, user} =
  Accounts.create_user(%{
    username: "fly-apps",
    avatar_url: "https://avatars.githubusercontent.com/u/59829569?v=4"
  })

{:ok, repo} =
  Repos.create_repo(%{
    name: "tictac",
    full_name: "fly-apps/tictac",
    default_branch: "main",
    fork: false,
    user_id: user.id
  })

{:ok, _} =
  Notebooks.create_notebook(%{
    content: content,
    github_owner_login: "fly-apps",
    github_repo_name: "tictac",
    github_filename: "game_state.livemd",
    github_html_url:
      "https://github.com/fly-apps/tictac/blob/fffbcc8d163c2ba0ad254d96351a7cf953226d67/notebook/game_state.livemd",
    github_owner_avatar_url: "https://avatars.githubusercontent.com/u/59829569?v=4",
    user_id: user.id,
    repo_id: repo.id,
    url: "https://github.com/fly-apps/tictac/blob/main/notebook/game_state.livemd"
  })
