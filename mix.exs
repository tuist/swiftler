defmodule Swiftler.MixProject do
  use Mix.Project

  @version "0.2.6"

  def project do
    [
      app: :swiftler,
      version: @version,
      elixir: "~> 1.18.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      aliases: aliases(),
      docs: docs()
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
      files: ~w(lib mix.exs README* LICENSE* CHANGELOG* docs),
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

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "docs/getting-started.md",
        "docs/swift-integration.md",
        "docs/api-reference.md",
        "docs/troubleshooting.md",
        "CHANGELOG.md": [title: "Changelog"],
        LICENSE: [title: "License"]
      ],
      groups_for_extras: [
        "Getting Started": ["README.md", "docs/getting-started.md"],
        Guides: ["docs/swift-integration.md", "docs/api-reference.md"],
        Resources: ["docs/troubleshooting.md", "CHANGELOG.md", "LICENSE"]
      ],
      groups_for_modules: [
        "Public API": [Swiftler, Swiftler.Macros],
        "Mix Tasks": ~r/^Mix.Tasks/,
        Internal: [Swiftler.Compiler]
      ],
      source_ref: "v#{@version}",
      source_url: "https://github.com/tuist/swiftler",
      homepage_url: "https://github.com/tuist/swiftler"
    ]
  end
end
