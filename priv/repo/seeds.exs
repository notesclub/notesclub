# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias Notesclub.Notebooks.Notebook

for i <- 1..7 do
  Notesclub.Repo.insert!(%Notebook{github_owner_login: "curie", github_repo_name: "radioactivity", github_filename: "polonium.livemd", github_html_url: "https://github.com/curie/radioactivity/#{i}.../polonium.livemd"})
end
