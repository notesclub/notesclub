defmodule Notesclub.Stars do
  @moduledoc """
  Context for managing notebook stars (favourites) by users.
  """

  import Ecto.Query, warn: false

  alias Notesclub.Accounts.User
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Notebooks.NotebookUser
  alias Notesclub.Repo

  @spec toggle_star(Notesclub.Notebooks.Notebook.t(), Notesclub.Accounts.User.t()) ::
          {:ok, Notesclub.Notebooks.NotebookUser.t()} | {:error, Ecto.Changeset.t()}

  def toggle_star(%Notebook{} = notebook, %User{} = user) do
    case Repo.get_by(NotebookUser, notebook_id: notebook.id, user_id: user.id) do
      nil ->
        %NotebookUser{}
        |> NotebookUser.changeset(%{notebook_id: notebook.id, user_id: user.id})
        |> Repo.insert()

      notebook_user ->
        Repo.delete(notebook_user)
    end
  end

  def starred?(%Notebook{} = notebook, %User{} = user) do
    Repo.get_by(NotebookUser, notebook_id: notebook.id, user_id: user.id) != nil
  end

  def star_count(%Notebook{} = notebook) do
    NotebookUser
    |> where([nu], nu.notebook_id == ^notebook.id)
    |> Repo.aggregate(:count, :id)
  end
end
