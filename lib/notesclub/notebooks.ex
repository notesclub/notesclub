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
  alias Notesclub.Notebooks.Urls
  alias Notesclub.NotebooksPackages.NotebookPackage
  alias Notesclub.Packages
  alias Notesclub.Repos
  alias Notesclub.Repos.Repo, as: RepoSchema

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
        {:require_content, true}, query ->
          where(query, [notebook], not is_nil(notebook.content))

        {:select_content, true}, query ->
          select_merge(query, [:content])

        {:order, :desc}, query ->
          order_by(query, desc: :id)

        {:order, :random}, query ->
          order_by(query, fragment("RANDOM()"))

        {:order, :clap_count}, query ->
          order_by(query, desc: :clap_count)

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
  end

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

  iex> save_notebook(%{github_html_url: "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd", ...})
  {:ok, %Notebook{}}

  iex> save_notebook(%{field: bad_value})
  {:error, %Ecto.Changeset{}}
  """
  @spec save_notebook(map) :: {:ok, Notebook.t()} | {:error, Ecto.Changeset.t()}
  def save_notebook(attrs) do
    attrs = attrs |> put_repo_id() |> put_url()

    notebook =
      get_notebook_for_save(
        url: attrs[:url],
        github_html_url: attrs[:github_html_url],
        repo_name: attrs[:github_repo_name],
        username: attrs[:github_owner_login]
      )

    if notebook do
      update_notebook(notebook, attrs)
    else
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

  @spec increase_clap_count(integer()) ::
          {:ok, Notebook.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Increments the `clap_count` of the given notebook by 1 and updates it in the database.

  ## Parameters
  - `notebook`: The `%Notebook{}` struct whose count you want to increment.

  ## Returns
  - {:ok, %Notebook{}} on successful update.
  - {:error, changeset} on an error during update.
  """
  def increase_clap_count(notebook_id) when is_integer(notebook_id) do
    case get_notebook(notebook_id) do
      nil ->
        {:error, :not_found}

      %Notebook{} = notebook ->
        new_count = notebook.clap_count + 1
        update_notebook(notebook, %{clap_count: new_count})
    end
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

  def get_most_recent_clapped_notebook do
    Notebook
    |> where([n], not is_nil(n.clap_count))
    |> where([n], not is_nil(n.content))
    |> where([n], fragment("length(?)", n.content) >= 200)
    |> where([n], n.inserted_at >= from_now(-14, "day"))
    |> order_by(desc: :clap_count)
    |> limit(1)
    |> preload(:user)
    |> Repo.one()
  end
end
