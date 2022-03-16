# GoogleSignedUrl

Generates signed URLs for Google Cloud Storage without depending on gcloud/gsutil.
Only thing required is a valid service account credentials file.

Based on Googles Reference implementation in Python:
https://cloud.google.com/storage/docs/access-control/signing-urls-manually

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `google_signed_url` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:google_signed_url, "~> 1.0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/google_signed_url>.

