defmodule Notesclub.Notebooks do
  @moduledoc """
  The Notebooks context.
  """

  import Ecto.Query, warn: false
  alias Notesclub.Repo

  alias Notesclub.Accounts
  alias Notesclub.Accounts.User
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Notebooks.NotebookUser
  alias Notesclub.Notebooks.Rater
  alias Notesclub.Notebooks.Urls
  alias Notesclub.NotebooksPackages.NotebookPackage
  alias Notesclub.Packages
  alias Notesclub.PublishLogs.PublishLog
  alias Notesclub.Repos
  alias Notesclub.Repos.Repo, as: RepoSchema
  alias Notesclub.Workers.NotebookRatingWorker
  alias Notesclub.Workers.UrlContentSyncWorker

  require Logger

  @default_per_page 15
  @default_fields Notebook.__schema__(:fields) -- [:content]

  @doc """
  Returns the latest notebook inserted
  """
  @spec get_latest_notebook :: Notebook.t()
  def get_latest_notebook do
    Notebook |> last(:inserted_at) |> Repo.one()
  end

  @doc """
  Returns the list of notebooks.

  ## Examples

      iex> list_notebooks()
      [%Notebook{}, ...]

  """
  @spec list_notebooks(any) :: [Notebook.t()]
  def list_notebooks(opts \\ []) do
    preload = opts[:preload] || []
    opts = replace_package_name_with_ids(opts, opts[:package_name])

    base_query =
      from n in Notebook,
        join: u in User,
        on: n.user_id == u.id,
        select: ^@default_fields,
        preload: ^preload

    Enum.reduce(
      opts,
      base_query,
      fn
        {:stars_gte, stars}, query ->
          query
          |> join(:left, [n], nu in NotebookUser, on: nu.notebook_id == n.id)
          |> group_by([n], n.id)
          |> having([n, nu], count(nu.id) >= ^stars)

        {:require_content, true}, query ->
          where(query, [notebook], not is_nil(notebook.content))

        {:select_content, true}, query ->
          select_merge(query, [:content])

        {:order, :desc}, query ->
          order_by(query, desc: :id)

        {:order, :random}, query ->
          order_by(query, fragment("RANDOM()"))

        {:order, :star_count}, query ->
          # Subquery to count stars per notebook
          star_counts =
            from nu in NotebookUser,
              group_by: nu.notebook_id,
              select: %{notebook_id: nu.notebook_id, star_count: count(nu.id)}

          query
          # Left join the star counts subquery
          |> join(:left, [n, u], sc in subquery(star_counts), on: n.id == sc.notebook_id)
          # Order by the joined star_count field, handling NULLs
          |> order_by([n, u, sc], desc_nulls_last: sc.star_count)

        {:order, :ai_rating}, query ->
          order_by(query, desc_nulls_last: :ai_rating)

        {:github_filename, github_filename}, query ->
          search = "%#{github_filename}%"
          where(query, [notebook], ilike(notebook.github_filename, ^search))

        {:searchable, searchable}, query ->
          search = "%#{searchable}%"

          where(
            query,
            [notebook, u],
            fragment(
              "CONCAT(?, ?, ?, ?, ?) ilike ?",
              notebook.title,
              notebook.github_filename,
              u.name,
              notebook.github_owner_login,
              notebook.github_repo_name,
              ^search
            )
          )

        {:github_owner_login, github_owner_login}, query ->
          where(query, [notebook], notebook.github_owner_login == ^github_owner_login)

        {:github_repo_name, github_repo_name}, query ->
          where(query, [notebook], notebook.github_repo_name == ^github_repo_name)

        {:content, content}, query ->
          search = "%#{content}%"
          where(query, [notebook], ilike(notebook.content, ^search))

        {:full_text_search, search_term}, query when is_nil(search_term) ->
          # If search_term is nil, return the query as-is
          query

        {:full_text_search, search_term}, query ->
          # Prefix match for lexemes in full-text search
          tsquery =
            search_term
            |> String.split(" ")
            |> Enum.map(&String.trim/1)
            |> Enum.reject(&(&1 == ""))
            # allow partial lexeme match
            |> Enum.map_join(" & ", &"#{&1}:*")

          # Join user so we can search in user.name via trigram
          query =
            join(query, :inner, [n], u in User, on: u.id == n.user_id)

          # Combine full-text search with trigram substring search
          # Prioritize user name matches by using a more sophisticated ranking
          where(
            query,
            [n, u],
            fragment("? @@ to_tsquery('english', ?)", n.search_vector, ^tsquery) or
              fragment("? ILIKE ?", n.github_owner_login, ^"%#{search_term}%") or
              fragment("? ILIKE ?", n.github_repo_name, ^"%#{search_term}%") or
              fragment("? ILIKE ?", u.name, ^"%#{search_term}%") or
              fragment("? ILIKE ?", n.github_filename, ^"%#{search_term}%")
          )

        {:order, :relevance}, query ->
          # Order by relevance using ts_rank
          search_term = opts[:full_text_search]
          apply_relevance_ordering(query, search_term)

        {:ids, ids}, query ->
          where(query, [notebook], notebook.id in ^ids)

        {:exclude_ids, exclude_ids}, query ->
          where(query, [notebook], notebook.id not in ^exclude_ids)

        {:repo_id, repo_id}, query ->
          where(query, [notebook], notebook.repo_id == ^repo_id)

        {:page, page}, query ->
          case Keyword.fetch(opts, :per_page) do
            {:ok, per_page} -> paginate(query, page, per_page)
            :error -> paginate(query, page, @default_per_page)
          end

        _, query ->
          query
      end
    )
    |> Repo.all()
  end

  @spec replace_package_name_with_ids(list, binary | nil) :: list
  defp replace_package_name_with_ids(opts, nil), do: opts

  defp replace_package_name_with_ids(opts, package_name) do
    case Packages.get_by_name(package_name, preload: :notebooks) do
      nil ->
        opts

      package ->
        notebook_ids = Enum.map(package.notebooks, & &1.id)

        opts
        |> Keyword.delete(:package_name)
        |> Keyword.put(:ids, notebook_ids)
    end
  end

  @spec apply_relevance_ordering(Ecto.Query.t(), binary | nil) :: Ecto.Query.t()
  defp apply_relevance_ordering(query, nil), do: query

  defp apply_relevance_ordering(query, search_term) do
    formatted_query =
      if search_term do
        search_term
        |> String.split(" ")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(&(&1 != ""))
        |> Enum.join(" & ")
      else
        ""
      end

    if formatted_query != "" do
      # Join with user table to access user name for ranking
      query = join(query, :inner, [n], u in User, on: u.id == n.user_id)

      order_by(query, [n, u],
        desc:
          fragment(
            # Boost ranking when user name matches the search term
            "ts_rank(?, to_tsquery('english', ?)) + CASE WHEN ? ILIKE ? THEN 2.0 ELSE 0.0 END",
            n.search_vector,
            ^formatted_query,
            u.name,
            ^"%#{search_term}%"
          )
      )
    else
      query
    end
  end

  @spec list_notebooks_since(integer()) :: [Notebook.t()]
  def list_notebooks_since(num_days_ago) when is_integer(num_days_ago) do
    from(n in Notebook,
      where: n.inserted_at >= from_now(-(^num_days_ago), "day"),
      order_by: -n.id
    )
    |> Repo.all()
  end

  @doc """
  Returns the notebook with the highest clap_count from the last specified number of days.
  Preloads user and repo associations.

  ## Examples

      iex> get_top_notebook_by_claps_since(14)
      %Notebook{}

  """
  @spec get_top_notebook_by_claps_since(integer()) :: Notebook.t() | nil
  def get_top_notebook_by_claps_since(num_days_ago) when is_integer(num_days_ago) do
    from(n in Notebook,
      where: n.inserted_at >= from_now(-(^num_days_ago), "day"),
      order_by: [desc: :clap_count, desc: :id],
      preload: [:user, :repo],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Resets the repo's notebooks url depending on notebook.github_html_url and repo.default_branch

  ## Examples

      iex> enqueue_url_and_content_sync(%Repo{id: 1})
      {:ok, %{"notebook_1" =>  %Notesclub.Notebooks.Notebook{...}, ...}}

  """
  @spec enqueue_url_and_content_sync(RepoSchema.t()) ::
          {:ok, %{binary => Notebook.t()}} | {:error, %{binary => Ecto.Changeset.t()}}
  def enqueue_url_and_content_sync(%RepoSchema{id: repo_id}) do
    [repo_id: repo_id]
    |> list_notebooks()
    |> Enum.reduce(Ecto.Multi.new(), fn
      %Notebook{} = notebook, query ->
        Oban.insert(
          query,
          "content_sync_worker_#{notebook.id}",
          UrlContentSyncWorker.new(%{notebook_id: notebook.id})
        )

      _, query ->
        query
    end)
    |> Repo.transaction()
  end

  @doc """
  Returns the notebooks from an author in desc order

  ## Examples

      iex> list_author_notebooks_desc("someone")
      [%Notebook{}, ...]

  """
  @spec list_author_notebooks_desc(binary) :: [Notebook.t()] | nil
  def list_author_notebooks_desc(author) when is_binary(author) do
    from(n in Notebook,
      where: n.github_owner_login == ^author,
      order_by: -n.id
    )
    |> Repo.all()
  end

  @doc """
  Returns the notebooks within a repo in desc order

  ## Examples

      iex> list_repo_author_notebooks_desc("my_repo", "my_login")
      [%Notebook{}, ...]

  """
  @spec list_repo_author_notebooks_desc(binary, binary) :: [Notebook.t()]
  def list_repo_author_notebooks_desc(repo_name, author_login)
      when is_binary(repo_name) and is_binary(author_login) do
    from(n in Notebook,
      where: n.github_repo_name == ^repo_name,
      where: n.github_owner_login == ^author_login,
      order_by: -n.id
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of random notebooks

  ## Examples

      iex> list_random_notebooks(%{limit: 2}
      [%Notebook{}, %Notebook{}]

  """
  def list_random_notebooks(%{limit: limit}) do
    from(n in Notebook,
      order_by: fragment("RANDOM()"),
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets a single notebook.

  Returns nil if the Notebook does not exist.

  ## Examples

      iex> get_notebook(123)
      %Notebook{}

      iex> get_notebook(456)
      nil

  """
  @spec get_notebook(any) :: Notebook.t() | nil
  def get_notebook(id), do: Repo.get(Notebook, id)

  def get_notebook(id, preload: tables) do
    from(n in Notebook,
      where: n.id == ^id,
      preload: ^tables
    )
    |> Repo.one()
  end

  @doc """
  Gets a single notebook.

  Raises `Ecto.NoResultsError` if the Notebook does not exist.

  ## Examples

      iex> get_notebook!(123)
      %Notebook{}

      iex> get_notebook!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_notebook!(number) :: Notebook.t()
  def get_notebook!(id), do: Repo.get!(Notebook, id)

  def get_notebook!(id, preload: tables) do
    from(n in Notebook,
      where: n.id == ^id,
      preload: ^tables
    )
    |> Repo.one!()
  end

  @doc """
  Gets a notebook by its url or filename, owner and repo
  This allows us to override a file if the url has changed

  ## Examples
    iex> get_by(url: "https://github.com/.../file.livemd")
    true

  """

  @spec get_by([...]) :: Notebook.t() | nil
  def get_by(ops) do
    get_by_query(ops)
    |> Repo.one()
  end

  @type get_by_ops ::
          [
            github_filename: binary(),
            github_owner_login: binary(),
            github_html_url: binary(),
            github_repo_name: binary(),
            url: binary()
          ]

  @spec get_by!(get_by_ops()) :: Notebook.t()
  def get_by!(ops) do
    get_by_query(ops)
    |> Repo.one!()
  end

  defp get_by_query(ops) do
    preload = ops[:preload] || []

    Enum.reduce(ops, from(n in Notebook, preload: ^preload), fn
      {:github_filename, github_filename}, query ->
        where(query, [notebook], notebook.github_filename == ^github_filename)

      {:github_owner_login, github_owner_login}, query ->
        where(query, [notebook], notebook.github_owner_login == ^github_owner_login)

      {:github_html_url, github_html_url}, query ->
        where(query, [notebook], notebook.github_html_url == ^github_html_url)

      {:github_repo_name, github_repo_name}, query ->
        where(query, [notebook], notebook.github_repo_name == ^github_repo_name)

      {:url, url}, query ->
        where(query, [notebook], notebook.url == ^url)

      _, query ->
        query
    end)
  end

  @doc """
  Creates a notebook.
  It also:
  - creates the associations user and repo if they don't exist

  ## Examples

      iex> create_notebook(%{field: value})
      {:ok, %Notebook{}}

      iex> create_notebook(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_notebook(any) :: {:ok, Notebook.t()} | {:error, Ecto.Changeset.t()}
  def create_notebook(attrs \\ %{}) do
    %Notebook{}
    |> Notebook.changeset(attrs)
    |> maybe_put_repo_id(attrs)
    |> maybe_put_user_id(attrs)
    |> maybe_put_user_and_repo_assoc(attrs)
    |> Repo.insert()
    |> set_user_id(attrs)
    |> set_ai_rating()
  end

  defp set_ai_rating({:ok, notebook}) do
    # Enqueue notebook rating worker to handle AI rating asynchronously
    %{notebook_id: notebook.id}
    |> NotebookRatingWorker.new()
    |> Oban.insert()

    {:ok, notebook}
  end

  defp set_ai_rating(result), do: result
  defp set_user_id(result, %{user_id: _}), do: result

  # When we put the associations notebook.repo and notebook.repo.user
  #  we need to manually set notebook.user_id
  defp set_user_id({:ok, notebook}, _) do
    repo = Repos.get_repo!(notebook.repo_id)

    case update_notebook(notebook, %{user_id: repo.user_id}) do
      {:ok, notebook} ->
        {:ok, notebook}

      {:error, _} ->
        Logger.warning(
          "create_notebook/1 created notebook id #{notebook.id} but couldn't save notebook.user_id. However, this is deprecated as we saved notebook.repo.user_id"
        )

        {:ok, notebook}
    end
  end

  defp set_user_id({:error, changeset}, _) do
    {:error, changeset}
  end

  def maybe_put_repo_id(changeset, %{repo_id: _, user_id: _}), do: changeset
  def maybe_put_repo_id(changeset, %{repo_id: nil}), do: changeset

  def maybe_put_repo_id(changeset, %{repo_id: repo_id}) do
    repo = Repos.get_repo!(repo_id)
    Ecto.Changeset.put_change(changeset, :user_id, repo.user_id)
  end

  def maybe_put_repo_id(changeset, %{github_repo_name: nil}), do: changeset

  def maybe_put_repo_id(changeset, %{
        github_repo_name: repo_name,
        github_owner_login: username
      }) do
    case Repos.get_by(%{full_name: "#{username}/#{repo_name}"}) do
      nil ->
        changeset

      repo ->
        changeset
        |> Ecto.Changeset.put_change(:repo_id, repo.id)
        |> Ecto.Changeset.put_change(:user_id, repo.user_id)
    end
  end

  def maybe_put_repo_id(changeset, %{github_repo_name: github_repo_name}) do
    case Repos.get_by(%{name: github_repo_name}) do
      nil ->
        changeset

      repo ->
        changeset
        |> Ecto.Changeset.put_change(:repo_id, repo.id)
        |> Ecto.Changeset.put_change(:user_id, repo.user_id)
    end
  end

  def maybe_put_user_id(changeset, %{user_id: _}), do: changeset

  def maybe_put_user_id(changeset, %{github_owner_login: github_owner_login}) do
    case Accounts.get_by_username(github_owner_login) do
      nil -> changeset
      %User{} = user -> Ecto.Changeset.put_change(changeset, :user_id, user.id)
    end
  end

  def maybe_put_user_and_repo_assoc(changeset, attrs) do
    user_id = Ecto.Changeset.get_change(changeset, :user_id)
    repo_id = Ecto.Changeset.get_change(changeset, :repo_id)

    case {user_id, repo_id} do
      {nil, nil} ->
        Ecto.Changeset.put_assoc(changeset, :repo, %RepoSchema{
          name: attrs[:github_repo_name],
          full_name: attrs[:github_repo_full_name],
          fork: attrs[:github_repo_fork],
          user: %User{
            github_id: attrs[:github_owner_id],
            username: attrs[:github_owner_login],
            avatar_url: attrs[:github_owner_avatar_url]
          }
        })

      {user_id, nil} ->
        Ecto.Changeset.put_assoc(changeset, :repo, %RepoSchema{
          name: attrs.github_repo_name,
          user_id: user_id
        })

      {_user_id, _repo_id} ->
        changeset
    end
  end

  @doc """
  Creates or updates a notebook depending on url
  url (default branch url) is generated from github_html_url (commit url) if url is not present

  If url or github_html_url exist or can be generated, we create a notebook. Otherwise, we update it.
  If we create a notebook, we'll also create a user and repo if they don't exist.any()
  Yet, if we update a notebook, we do NOT create user and repo if missing.
    This should NOT be a problem as user and repo creation is handled upon creation.

  ## Examples

  iex> save_notebook(%{github_html_url: "https://github.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd", ...})
  {:ok, %Notebook{}}

  iex> save_notebook(%{field: bad_value})
  {:error, %Ecto.Changeset{}}
  """
  @spec save_notebook(map) ::
          {:ok, Notebook.t()} | {:error, Ecto.Changeset.t()} | :fork_deleted | :fork_skipped
  def save_notebook(attrs) do
    attrs = attrs |> put_repo_id() |> put_url()

    notebook =
      get_notebook_for_save(
        url: attrs[:url],
        github_html_url: attrs[:github_html_url],
        repo_name: attrs[:github_repo_name],
        username: attrs[:github_owner_login]
      )

    full_name = "#{attrs[:github_owner_login]}/#{attrs[:github_repo_name]}"
    is_fork = !!Repos.get_by(%{full_name: full_name, fork: true})

    cond do
      notebook && is_fork ->
        delete_notebook(notebook)
        :fork_deleted

      notebook ->
        update_notebook(notebook, attrs)

      is_fork ->
        :fork_skipped

      true ->
        create_notebook(attrs)
    end
  end

  defp get_notebook_for_save(url: nil, github_html_url: nil), do: nil
  defp get_notebook_for_save(url: nil, repo_name: nil), do: nil
  defp get_notebook_for_save(url: nil, username: nil), do: nil

  defp get_notebook_for_save(url: url) do
    Notebooks.get_by(url: url)
  end

  defp get_notebook_for_save(
         url: _,
         github_html_url: github_html_url,
         repo_name: repo_name,
         username: username
       ) do
    notebook =
      case Repos.get_by(%{full_name: "#{username}/#{repo_name}"}) do
        nil ->
          nil

        repo ->
          url = Urls.default_branch_url(github_html_url, repo.default_branch)
          Notebooks.get_by(url: url)
      end

    notebook || (github_html_url && Notebooks.get_by(github_html_url: github_html_url))
  end

  defp get_notebook_for_save(github_html_url: github_html_url) do
    Notebooks.get_by(github_html_url: github_html_url)
  end

  defp put_repo_id(%{github_repo_name: repo_name, github_owner_login: username} = attrs) do
    case Repos.get_by(%{full_name: "#{username}/#{repo_name}"}) do
      nil -> attrs
      repo -> Map.put_new(attrs, :repo_id, repo.id)
    end
  end

  defp put_repo_id(attrs), do: attrs

  defp put_url(%{github_html_url: github_html_url, repo_id: repo_id} = attrs) do
    url = build_url(%{github_html_url: github_html_url, repo_id: repo_id})
    Map.put_new(attrs, :url, url)
  end

  defp put_url(attrs), do: attrs

  defp build_url(%{repo_id: repo_id, github_html_url: github_html_url}) do
    case Repos.get_repo(repo_id) do
      nil ->
        nil

      %RepoSchema{default_branch: nil} ->
        nil

      %RepoSchema{default_branch: default_branch} ->
        Urls.default_branch_url(github_html_url, default_branch)
    end
  end

  @doc """
  Updates a notebook.

  ## Examples

      iex> update_notebook(notebook, %{field: new_value})
      {:ok, %Notebook{}}

      iex> update_notebook(notebook, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_notebook(Notebook.t(), map()) :: {:ok, Notebook.t()} | {:error, Ecto.Changeset.t()}
  def update_notebook(%Notebook{} = notebook, attrs) do
    notebook
    |> Notebook.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notebook.

  ## Examples

      iex> delete_notebook(notebook)
      {:ok, %Notebook{}}

      iex> delete_notebook(notebook)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_notebook(Notebook.t()) :: {:ok, Notebook.t()} | {:error, Ecto.Changeset.t()}
  def delete_notebook(%Notebook{} = notebook) do
    Repo.delete(notebook)
  end

  def delete_notebooks(%{username: username, except_ids: except_ids}) do
    notebook_ids =
      from(n in Notebook,
        where: n.github_owner_login == ^username,
        where: n.id not in ^except_ids,
        select: n.id
      )
      |> Repo.all()

    Repo.transaction(fn ->
      Repo.delete_all(from(np in NotebookPackage, where: np.notebook_id in ^notebook_ids))
      Repo.delete_all(from(n in Notebook, where: n.id in ^notebook_ids))
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notebook changes.

  ## Examples

      iex> change_notebook(notebook)
      %Ecto.Changeset{data: %Notebook{}}

  """
  @spec change_notebook(Notebook.t(), map()) :: Ecto.Changeset.t()
  def change_notebook(%Notebook{} = notebook, attrs \\ %{}) do
    Notebook.changeset(notebook, attrs)
  end

  @spec count :: number
  def count do
    Repo.aggregate(Notebook, :count, :id)
  end

  def content_fragment(%Notebook{content: nil}, _search), do: nil
  def content_fragment(_notebook, nil), do: nil

  def content_fragment(%Notebook{content: content}, search) do
    search
    |> Regex.escape()
    |> extract_line(content)
    |> extract_surounding(search)
  end

  defp extract_line(search, content) do
    case Regex.run(~r/.*#{search}.*/i, content) do
      nil -> nil
      list -> List.first(list)
    end
  end

  defp extract_surounding(nil, _), do: nil

  defp extract_surounding(line, search) do
    [part_before, part_after | _] = String.split(line, ~r/#{search}/i)
    len = String.length(part_before)
    part_before = String.slice(part_before, (len - 25)..(len - 1))
    part_after = String.slice(part_after, 0..25)
    "...#{part_before}#{search}#{part_after}..."
  end

  def paginate(query, 0, per_page), do: limit(query, ^per_page)

  def paginate(query, page, per_page) do
    offset_by = per_page * page

    query
    |> limit(^per_page)
    |> offset(^offset_by)
  end

  def extract_title(nil), do: nil

  def extract_title(content) do
    case Regex.scan(~r/#\s+(.+)/, content) do
      [[_full_capture, capture] | _] -> capture
      _ -> nil
    end
  end

  def update_all_titles do
    list_notebooks()
    |> Enum.map(fn n ->
      update_notebook(n, %{title: extract_title(n.content)})
    end)
  end

  @doc """
  Rates a notebook based on how interesting it would be to Elixir developers.
  Returns a rating from 0 (not interesting) to 1000 (max interest).

  Uses OpenRouter AI to analyze the notebook content and provide a structured rating
  along with relevant tags for categorization.

  ## Examples

      iex> rate_notebook_interest(notebook)
      {:ok, 750}

      iex> rate_notebook_interest(notebook_without_elixir)
      {:ok, 120}
  """
  @spec rate_notebook_interest(Notebook.t()) :: {:ok, integer()} | {:error, term()}
  def rate_notebook_interest(%Notebook{} = notebook) do
    Rater.rate_notebook_interest(notebook)
  end

  # Gets starred notebooks associated with a user, preloading necessary associations
  @spec list_starred_notebooks_by_user(User.t(), Keyword.t()) :: [Notebook.t()]
  def list_starred_notebooks_by_user(%User{} = user, opts \\ []) do
    preload = opts[:preload] || []
    per_page = opts[:per_page] || @default_per_page
    page = opts[:page] || 0

    base_query =
      from(n in Notebook,
        join: f in NotebookUser,
        on: f.notebook_id == n.id,
        where: f.user_id == ^user.id,
        select: ^@default_fields,
        preload: ^preload,
        order_by: [desc: f.inserted_at]
      )

    Enum.reduce(
      opts,
      base_query,
      fn
        {:exclude_ids, exclude_ids}, query ->
          where(query, [n], n.id not in ^exclude_ids)

        {:require_content, true}, query ->
          where(query, [n], not is_nil(n.content))

        # Note: pagination options are handled outside the reduce
        {:page, _}, query ->
          query

        {:per_page, _}, query ->
          query

        {:preload, _}, query ->
          query

        # Ignore other options for now or add specific handlers if needed
        _, query ->
          query
      end
    )
    # Apply pagination after filtering
    |> paginate(page, per_page)
    |> Repo.all()
  end

  @doc """
  Returns a list of notebooks that share at least one package with the given notebook.
  The notebooks are ordered randomly and limited by the given limit.
  """
  def get_related_by_packages(%Notebook{id: notebook_id}, opts \\ []) do
    limit = opts[:limit] || 5
    preload = opts[:preload] || []
    preload = [:packages | preload]

    from(n in Notebook,
      join: np in NotebookPackage,
      on: np.notebook_id == n.id,
      join: p in assoc(np, :package),
      where: n.id != ^notebook_id,
      where:
        p.id in subquery(
          from(np in NotebookPackage,
            where: np.notebook_id == ^notebook_id,
            select: np.package_id
          )
        ),
      preload: ^preload,
      distinct: n.id,
      order_by: fragment("RANDOM()"),
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of random notebooks that have at least 3 packages.
  """
  def get_random_notebooks(opts \\ []) do
    limit = opts[:limit] || 3
    exclude_ids = opts[:exclude_ids] || []
    preload = opts[:preload] || []
    preload = [:packages | preload]

    from(n in Notebook,
      join: np in NotebookPackage,
      on: np.notebook_id == n.id,
      where: n.id not in ^exclude_ids,
      group_by: n.id,
      having: count(np.package_id) >= 3,
      order_by: fragment("RANDOM()"),
      limit: ^limit,
      preload: ^preload
    )
    |> Repo.all()
  end

  @doc """
  Returns the most starred notebook that has not been published to the given platform.

  ## Examples

      iex> get_non_published_most_starred_notebook("x")
      %Notebook{}

      iex> get_non_published_most_starred_notebook("x")
      nil
  """
  def get_non_published_most_starred_notebook(platform) do
    # Subquery to get star counts for notebooks
    star_counts =
      from nu in NotebookUser,
        group_by: nu.notebook_id,
        select: %{notebook_id: nu.notebook_id, star_count: count(nu.id)}

    Notebook
    |> join(:inner, [n], sc in subquery(star_counts), on: n.id == sc.notebook_id)
    |> join(:left, [n, _sc], pl in PublishLog,
      on: pl.notebook_id == n.id and pl.platform == ^platform
    )
    |> where([n, _sc, pl], is_nil(pl.id))
    |> where([n], not is_nil(n.content))
    |> where([n], fragment("length(?)", n.content) >= 200)
    |> order_by([n, sc], desc: sc.star_count, asc: fragment("RANDOM()"))
    |> limit(1)
    |> preload(:user)
    |> Repo.one()
  end

  def get_non_published_highest_ai_rated_notebook(platform) do
    Notebook
    |> join(:left, [n], pl in PublishLog, on: pl.notebook_id == n.id and pl.platform == ^platform)
    |> where([n, pl], is_nil(pl.id))
    |> where([n], not is_nil(n.content))
    |> where([n], not is_nil(n.ai_rating))
    |> where([n], fragment("length(?)", n.content) >= 200)
    #  Randomly order notebooks with same rating to avoid sharing same-author notebooks in a row
    |> order_by([n], desc: n.ai_rating, asc: fragment("RANDOM()"))
    |> limit(1)
    |> preload(:user)
    |> Repo.one()
  end

  @spec get_star_count(integer()) :: integer()
  def get_star_count(notebook_id) when is_integer(notebook_id) do
    from(nu in NotebookUser,
      where: nu.notebook_id == ^notebook_id,
      select: count(nu.id)
    )
    |> Repo.one()
  end
end
