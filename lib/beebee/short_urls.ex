defmodule BeeBee.ShortUrl do
  @moduledoc """
  Behaviour for storage.
  """

  @callback create(String.t(), String.t()) :: {:ok, Enum.t()} | {:error, any}

  @callback find(String.t()) :: {:ok, String.t()} | {:error, any}

  @callback stats :: Enumerable.t()

  @doc """
  Save a new url and short_tag to the underlying storage backend. If no short_tag
  is provided, the system will generate a random one.
  """
  @spec create(String.t(), String.t()) :: {:ok, Enum.t()} | {:error, any}
  def create(url, short_tag \\ random_short_tag()), do: storage_backend().create(url, short_tag)

  @doc """
  Returns a URL given the associated short_tag. It will increment the url hit count
  on every call to this function.
  """
  @spec find(String.t()) :: {:ok, String.t()} | {:error, any}
  def find(short_tag), do: storage_backend().find(short_tag)

  @doc """
  Returns all the URLs in the system with their short_tag and hit count statistics.
  """
  @spec stats :: Enumerable.t()
  def stats, do: storage_backend().stats()

  defp storage_backend do
    case Application.get_env(:beebee, :storage_backend) do
      {backend_module, _config} ->
        backend_module

      _ ->
        raise RuntimeError, "Beebee :storage_backend not configured"
    end
  end

  defp random_short_tag(bytes \\ 6) do
    bytes
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(case: :lower, padding: false)
  end
end
