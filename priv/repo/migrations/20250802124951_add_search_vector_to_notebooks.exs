defmodule Notesclub.Repo.Migrations.AddSearchVectorToNotebooks do
  use Ecto.Migration

  def change do
    # Add search vector column
    alter table(:notebooks) do
      add :search_vector, :tsvector
    end

    # Create GIN index for fast full-text search
    create index(:notebooks, [:search_vector], using: :gin)

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
