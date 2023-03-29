defmodule Notesclub.Notebooks.Paths do
  @moduledoc """
  Generate notebooks paths
  """

  @doc """
  Returns the Notesclub path given a GitHub url
  If the url contains /blob/main/ we remove blob/main and .livemd
  """
  def url_to_path(url) do
    path = String.replace(url, "https://github.com", "")

    if String.contains?(path, "/blob/main/") do
      path
      |> String.replace("blob/main/", "")
      |> String.replace(".livemd", "")
    else
      path
    end
  end

  @doc """
  Returns the GitHub url given a Notesclub path
  If the path does NOT contain .livemd, we add blob/main and .livemd
  """
  def path_to_url(path) do
    path =
      if String.contains?(path, ".livemd") do
        path
      else
        String.replace(path, ~r/^(\/[^\/]+\/[^\/]+\/)(.*)$/, "\\1blob/main/\\2") <> ".livemd"
      end

    "https://github.com#{path}"
  end

  @doc """
  Remove .livemd from local links. E.g. ../whatever.livemd -> ../whatever
  External links are kept. E.g. https://github.com/a/b/whatever.livemd is not replaced
  """
  def remove_livemd_extension_from_links(text) do
    String.replace(text, ~r/(\.\..+)\.livemd/, "\\1", global: true)
  end
end
