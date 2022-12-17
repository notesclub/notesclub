defmodule Notesclub.Repo.Migrations.TitleAndUrlsTextInsteadOfString do
  use Ecto.Migration

  def up do
    alter table(:notebooks) do
      modify :title, :text
      modify :url, :text
      modify :github_html_url, :text
    end
  end

  def down do
    alter table(:notebooks) do
      modify :title, :string
      modify :url, :string
      modify :github_html_url, :string
    end
  end
end
