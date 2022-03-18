defmodule GoogleSignedUrl.MixProject do
  use Mix.Project

  def project do
    [
      app: :google_signed_url,
      version: "1.0.2",
      description: "Generates signed URLs for Google Cloud Storage without depending on gcloud/gsutil",
      source_url: "https://github.com/hukl/google_signed_url",
      homepage_url: "https://github.com/hukl/google_signed_url",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/hukl/google_signed_url"}
      ],
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto, :public_key]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
    ]
  end
end
