defmodule Notesclub.Repo.Migrations.AddUserNameToSearchVector do
  use Ecto.Migration

  def up do
    # Drop the existing trigger first
    execute "DROP TRIGGER IF EXISTS notebooks_search_vector_update ON notebooks;"

    # Drop the existing function
    execute "DROP FUNCTION IF EXISTS notebooks_search_vector_update();"

    # Create the updated function that includes user name
    execute """
    CREATE OR REPLACE FUNCTION notebooks_search_vector_update() RETURNS trigger AS $$
    BEGIN
      NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.github_filename, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.github_owner_login, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE((
          SELECT u.name FROM users u WHERE u.id = NEW.user_id
        ), '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.github_repo_name, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.content, '')), 'D');
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Recreate the trigger
    execute """
    CREATE TRIGGER notebooks_search_vector_update
      BEFORE INSERT OR UPDATE ON notebooks
      FOR EACH ROW EXECUTE FUNCTION notebooks_search_vector_update();
    """

    # Update existing records to include user name in search vector
    execute """
    UPDATE notebooks SET search_vector =
      setweight(to_tsvector('english', COALESCE(title, '')), 'A') ||
      setweight(to_tsvector('english', COALESCE(github_filename, '')), 'B') ||
      setweight(to_tsvector('english', COALESCE((
        SELECT u.name FROM users u WHERE u.id = notebooks.user_id
      ), '')), 'C') ||
      setweight(to_tsvector('english', COALESCE(github_owner_login, '')), 'C') ||
      setweight(to_tsvector('english', COALESCE(github_repo_name, '')), 'C') ||
      setweight(to_tsvector('english', COALESCE(content, '')), 'D');
    """
  end

  def down do
    # Drop the trigger
    execute "DROP TRIGGER IF EXISTS notebooks_search_vector_update ON notebooks;"

    # Drop the function
    execute "DROP FUNCTION IF EXISTS notebooks_search_vector_update();"

    # Create a function to update the search vector
    execute """
    CREATE OR REPLACE FUNCTION notebooks_search_vector_update() RETURNS trigger AS $$
    BEGIN
      NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.github_filename, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.github_owner_login, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.github_repo_name, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.content, '')), 'D');
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Create trigger to automatically update search vector
    execute """
    CREATE TRIGGER notebooks_search_vector_update
      BEFORE INSERT OR UPDATE ON notebooks
      FOR EACH ROW EXECUTE FUNCTION notebooks_search_vector_update();
    """

    # Update existing records
    execute """
    UPDATE notebooks SET search_vector =
      setweight(to_tsvector('english', COALESCE(title, '')), 'A') ||
      setweight(to_tsvector('english', COALESCE(github_filename, '')), 'B') ||
      setweight(to_tsvector('english', COALESCE(github_owner_login, '')), 'C') ||
      setweight(to_tsvector('english', COALESCE(github_repo_name, '')), 'C') ||
      setweight(to_tsvector('english', COALESCE(content, '')), 'D');
    """
  end
end
