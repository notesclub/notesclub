defmodule Notesclub.Packages.Extractor do
  @moduledoc """
  A module to extract hex package names from a Livebook notebook
  """

  @doc """
  Extracts package names from the given content.
  """
  @spec extract_packages(binary | nil) :: [binary]
  def extract_packages(nil), do: []

  def extract_packages(content) do
    content
    |> extract_mix_install_content()
    |> extract_packages_from_mix_install()
    |> Enum.uniq()
  end

  @spec extract_mix_install_content(binary) :: binary
  defp extract_mix_install_content(content) do
    regex = ~r/Mix\.install\s*\(\s*\[\s*(.*?)\s*\]\s*/s

    case Regex.scan(regex, content) do
      [[_, mix_install_content]] -> mix_install_content
      _ -> ""
    end
  end

  @spec extract_packages_from_mix_install(binary) :: [binary]
  defp extract_packages_from_mix_install(content) do
    ~r/{:(\w+),[^}]+}/
    |> Regex.scan(content)
    |> Enum.map(fn [_, package_name] -> package_name end)
  end
end
