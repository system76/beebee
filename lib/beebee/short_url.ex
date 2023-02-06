defmodule BeeBee.ShortUrl do
  @moduledoc """
  Behaviour for storage.
  """

  @callback create(:inet.hostname(), String.t()) :: {:ok, Enum.t()} | {:error, any}

  @callback delete(String.t()) :: :ok | {:error, any}

  @callback find(String.t()) :: {:ok, String.t()} | {:error, any}

  @callback stats :: Enumerable.t()

  @doc """
  Save a new url and short_tag to the underlying storage backend. If no short_tag
  is provided, the system will generate a random one.
  """
  @spec create(map) :: {:ok, Enum.t()} | {:error, any}
  def create(%{"url" => url, "short_tag" => short_tag}) do
    with {:ok, valid_url} <- validate_url(url) do
      storage_backend().create(valid_url, short_tag)
    end
  end

  def create(%{"url" => _url} = params) do
    params
    |> Map.put("short_tag", random_short_tag())
    |> create()
  end

  @doc """
  Delete a short_tag from the underlying storage backend.
  """
  @spec delete(String.t()) :: :ok | {:error, any}
  def delete(short_tag), do: storage_backend().delete(short_tag)

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
    |> Base.url_encode64(padding: false)
  end

  # Validate URL to prevent most malicious attacks described on
  # https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html
  # Prevents invalid domains or javascript code but till doesn't prevent double redirection
  # from the target site to an attacker.
  def validate_url(url) do
    case URI.parse(url) do
      %URI{scheme: nil} ->
        {:error, "is missing a scheme (e.g. https)"}

      %URI{host: nil} ->
        {:error, "is missing a host"}

      %URI{host: host} ->
        case :inet.gethostbyname(Kernel.to_charlist(host)) do
          {:ok, _} -> {:ok, url}
          {:error, _} -> {:error, "invalid host"}
        end
    end
  end
end
