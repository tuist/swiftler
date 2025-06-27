defmodule Swiftler.MixProject do
  use Mix.Project

  def project do
    [
      app: :swiftler,
      version: "0.1.0",
      elixir: "~> 1.18.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Swiftler allows you to call Swift code from Elixir using NIFs.
    Similar to how Rustler works for Rust.
    """
  end

  defp package do
    [
      files: ~w(lib priv mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tuist/swiftler"}
    ]
  end

  defp aliases do
    [
      "compile.swift": ["swift.compile"],
      "clean.swift": ["swift.clean"]
    ]
  end
end
