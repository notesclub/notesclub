defmodule Notesclub.Repo.Migrations.AddIndexesForTrigramSearch do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    execute """
    CREATE INDEX IF NOT EXISTS users_name_trgm_idx
      ON users USING gin (name gin_trgm_ops);
    """

    execute """
    CREATE INDEX IF NOT EXISTS notebooks_github_owner_login_trgm_idx
      ON notebooks USING gin (github_owner_login gin_trgm_ops);
    """

    execute """
    CREATE INDEX IF NOT EXISTS notebooks_github_repo_name_trgm_idx
      ON notebooks USING gin (github_repo_name gin_trgm_ops);
    """

    execute """
    CREATE INDEX IF NOT EXISTS notebooks_github_filename_trgm_idx
      ON notebooks USING gin (github_filename gin_trgm_ops);
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS users_name_trgm_idx;"
    execute "DROP INDEX IF EXISTS notebooks_github_owner_login_trgm_idx;"
    execute "DROP INDEX IF EXISTS notebooks_github_repo_name_trgm_idx;"
    execute "DROP INDEX IF EXISTS notebooks_github_filename_trgm_idx;"
    execute "DROP EXTENSION IF EXISTS pg_trgm;"
  end
end
