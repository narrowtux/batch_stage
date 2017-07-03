defmodule BatchStage.Mixfile do
  use Mix.Project

  def project do
    [
      app: :batch_stage,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/narrowtux/batch_stage",
      docs: docs()
    ]
  end

  def description do
    "Elixir GenStage that batches events together so they are not sent one-by-one"
  end

  def package do
    [
      licenses: ["MIT"],
      maintainers: ["narrowtux"],
      links: %{"GitHub" => "https://github.com/narrowtux/batch_stage"}
    ]
  end

  def docs do
    [
      main: "BatchStage"
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:gen_stage, "~> 0.12.0"},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end
end
