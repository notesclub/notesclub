# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seed_many_notebooks.exs

alias Notesclub.Notebooks

Enum.each(1..100, fn i ->
  {:ok, _} =
    Notebooks.create_notebook(%{
      github_owner_login: "Test Owner Login With A Very Long Name",
      github_repo_name: "Test Repo Name With A Very Long Name",
      github_filename:
        "test_file_name_that_is_very_very_very_very_very_very_very_very_very_very_long.livemd",
      github_html_url:
        "https://github.com/fly-apps/tictac/blob/fffbcc8d163c2ba0ad254d96351a7cf953226d67/notebook/game_state.livemd#{i}",
      github_owner_avatar_url: "https://avatars.githubusercontent.com/u/59829569?v=4"
    })
end)
