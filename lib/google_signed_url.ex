defmodule GoogleSignedUrl do
  @moduledoc """
  Documentation for `GoogleSignedUrl`.
  """

  @doc """
  Generates signed URLs for Google Cloud Storage without depending on gcloud/gsutil.
  Only thing required is a valid service account credentials file.

  Based on Googles Reference implementation in Python:
  https://cloud.google.com/storage/docs/access-control/signing-urls-manually

      signing_option() ::
        {:expires, integer()}
        | {:headers, map()}
        | {:queries, map()}
        | {:subresource, String.t() | nil}

  ## Examples
      iex> GoogleSignedUrl.signed_url(
        "path/to/cred_file",
        "bucketname",
        "object_name",
        "PUT",
        expires: 3600,
        headers: %{"x-goog-test" => "value"},
        queries: %{"key" => "value"},
        subresource: "somestring"
      )
  """
  @type signing_option  :: {:expires, integer()} | {:headers, map()} | {:queries, map()} | {:subresource, String.t()|nil}
  @type signing_options :: [signing_option]

  @spec signed_url(String.t(), String.t(), String.t(), String.t(), signing_options) :: String.t()
  def signed_url(cred_file, bucket, object_name, method, opts \\ []) do
    default_opts = [
      expires: 604800,
      headers: %{},
      queries: %{},
      subresource: nil
    ]

    options = Keyword.merge(default_opts, opts)

    with(
      {:ok, http_method}  <- validate_method(method)
    ) do
      {:ok, raw_data}     = File.read(cred_file)
      {:ok, credentials}  = Jason.decode(raw_data)
      host                = "#{bucket}.storage.googleapis.com"
      escaped_object_name = URI.encode(object_name)
      canonical_uri       = "/#{escaped_object_name}"
      datetime_now        = DateTime.truncate(DateTime.utc_now(), :second)
      request_timestamp   = DateTime.to_iso8601(datetime_now)
      datestamp           = Date.to_iso8601(datetime_now)
      client_email        = credentials["client_email"]
      credential_scope    = "#{Regex.replace(~r/[-:]/, datestamp, "")}/auto/storage/goog4_request"
      credential          = "#{client_email}/#{credential_scope}"


      ordered_headers     = options[:headers]
                            |> downcase_headers
                            |> Map.put("host", host)
                            |> Enum.to_list()
                            |> :orddict.from_list()

      canonical_headers   = ordered_headers
                            |> Enum.map(fn({k, v}) -> "#{k}:#{v}" end)
                            |> Enum.concat([""])
                            |> Enum.join("\n")

      signed_headers      = ordered_headers
                            |> Enum.map(fn({k, _v}) -> k end)
                            |> Enum.join(";")

      canonical_query_string = %{
        "X-Goog-Algorithm"     => "GOOG4-RSA-SHA256",
        "X-Goog-Credential"    => credential,
        "X-Goog-Date"          => Regex.replace(~r/[-:]/, request_timestamp, ""),
        "X-Goog-Expires"       => Integer.to_string(options[:expires]),
        "X-Goog-SignedHeaders" => signed_headers
      }
      |> Map.merge(options[:queries])
      |> maybe_add_subresource(options[:subresource])
      |> encode_query_params()
      |> Enum.to_list()
      |> :orddict.from_list()
      |> Enum.map(fn({k, v}) -> "#{k}=#{v}" end)
      |> Enum.join("&")

      canonical_request = Enum.join([
        http_method,
        canonical_uri,
        canonical_query_string,
        canonical_headers,
        signed_headers,
        'UNSIGNED-PAYLOAD'
      ], "\n")

      canonical_request_hash = :crypto.hash(:sha256, canonical_request)
      |> Base.encode16(case: :lower)

      string_to_sign = Enum.join([
        "GOOG4-RSA-SHA256",
        Regex.replace(~r/[-:]/, request_timestamp, ""),
        credential_scope,
        canonical_request_hash
      ], "\n")

      [encoded_private_key] = :public_key.pem_decode(credentials["private_key"])
      private_key           = :public_key.pem_entry_decode(encoded_private_key)
      signature             = :public_key.sign(string_to_sign, :sha256, private_key, rsa_padding: :rsa_pkcs1_padding)
                              |> Base.encode16(case: :lower)

      Path.join([
        "https://#{host}",
        "#{canonical_uri}?#{canonical_query_string}&x-goog-signature=#{signature}"
      ])
    end
  end

  defp maybe_add_subresource(queries, nil) do
    queries
  end
  defp maybe_add_subresource(queries, subresource) do
    Map.put(queries, subresource, "")
  end

  defp downcase_headers(args) do
    map_fun = fn({k, v}) ->
      {String.downcase(k), String.downcase(v)}
    end
    Map.new(Enum.map(args, map_fun))
  end

  defp encode_query_params(args) do
    map_fun = fn({k, v}) ->
      {URI.encode_www_form(k), URI.encode_www_form(v)}
    end
    Map.new(Enum.map(args, map_fun))
  end

  defp validate_method(method) do
    valid_methods  = ["GET", "POST", "PUT", "DELETE", "PATCH"]

    with(
      true           <- is_binary(method),
      upcased_method <- String.upcase(method),
      true           <- Enum.member?(valid_methods, upcased_method)
    ) do
      {:ok, upcased_method}
    else
      _ -> {:error, :unsupported_method}
    end
  end
end
