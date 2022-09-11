# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias Notesclub.Notebooks.Notebook

search = %{order: "some order", page: 1, per_page: 7, response_body: %{}, response_headers: %{}, response_notebooks_count: 7, response_private: %{}, response_status: 42, url: "https://github.com/curie/radioactivity/.../polonium.livemd"}
  |> Notesclub.Searches.create_search()

for i <- 1..7 do
  {:ok, user} = %{name: Faker.Person.En.first_name()}
  |> Notesclub.Accounts.create_user()

  {:ok, repo} = %{name: Faker.Person.En.first_name(), user_id: user.id}
  |> Notesclub.Repos.create_repo()

  Notesclub.Repo.insert!(%Notebook{user_id: user.id, repo_id: repo.id, github_owner_login: "curie", github_repo_name: "radioactivity", github_filename: "polonium.livemd", github_html_url: "https://github.com/curie/radioactivity/#{i}.../polonium.livemd"}, search: search)
end
