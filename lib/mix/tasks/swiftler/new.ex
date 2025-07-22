defmodule Mix.Tasks.Swiftler.New do
  @moduledoc """
  Creates a new Swift NIF project.

  This task will:
  1. Create a Swift package in the native/ directory
  2. Generate a Package.swift file with Swiftler dependency
  3. Create example Swift source files with NIF exports
  4. Generate an Elixir module to load the NIF

  Usage:

      mix swiftler.new [options]

  Options:

      --name NAME           Name for the NIF module (defaults to project name)
      --module MODULE       Elixir module name (defaults to project name)
      --path PATH           Path to create the Swift package (defaults to "native")
      --swiftler-path PATH  Path to local Swiftler package (for development)

  Examples:

      # Create a basic NIF module
      mix swiftler.new

      # Create with custom name
      mix swiftler.new --name calculator --module MyApp.Calculator

      # Create in custom path  
      mix swiftler.new --path swift_nif

      # Use local Swiftler package
      mix swiftler.new --swiftler-path ../swiftler
  """

  use Mix.Task

  @shortdoc "Creates a new Swift NIF project"

  @switches [
    name: :string,
    module: :string,
    path: :string,
    swiftler_path: :string
  ]

  def run(args) do
    {opts, _args} = OptionParser.parse!(args, switches: @switches)

    # Get project information
    project_info = get_project_info()
    project_name = project_info[:name]
    project_app = project_info[:app]

    nif_name = opts[:name] || project_app
    module_name = opts[:module] || project_name
    swift_path = opts[:path] || "native"
    swiftler_path = opts[:swiftler_path]
    base_path = File.cwd!()

    Mix.shell().info("Creating Swift NIF project...")

    create_swift_package(base_path, swift_path, nif_name, project_name, swiftler_path)
    create_swift_sources(base_path, swift_path, nif_name)
    create_elixir_module(base_path, module_name, nif_name, swift_path)

    module_file_path = get_module_file_path(module_name)

    Mix.shell().info("""

    Swift NIF project created successfully!

    Next steps:
    1. Add Swiftler to your dependencies in mix.exs:

        def deps do
          [
            {:swiftler, github: "tuist/swiftler", branch: "main"}
          ]
        end

    2. Compile the Swift code:

        mix swift.compile

    3. Test your NIF:

        iex -S mix
        iex> #{module_name}.add(5, 3)
        8

    Your Swift code is in: #{swift_path}/
    Your Elixir module is: #{module_file_path}
    """)
  end

  # For testing - allows specifying a different base path
  def run_in_path(args, base_path) do
    {opts, _args} = OptionParser.parse!(args, switches: @switches)

    # Get project information
    project_info = get_project_info()
    project_name = project_info[:name]
    project_app = project_info[:app]

    nif_name = opts[:name] || project_app
    module_name = opts[:module] || project_name
    swift_path = opts[:path] || "native"
    swiftler_path = opts[:swiftler_path]

    create_swift_package(base_path, swift_path, nif_name, project_name, swiftler_path)
    create_swift_sources(base_path, swift_path, nif_name)
    create_elixir_module(base_path, module_name, nif_name, swift_path)

    {:ok,
     %{
       swift_path: Path.join(base_path, swift_path),
       module_path: Path.join(base_path, get_module_file_path(module_name)),
       nif_name: nif_name,
       module_name: module_name
     }}
  end

  defp get_project_info do
    try do
      config = Mix.Project.config()
      app_name = config[:app] |> to_string()
      module_name = Macro.camelize(app_name)

      # Avoid cyclic dependency when running from within Swiftler project
      if app_name == "swiftler" do
        %{name: "MyApp", app: "my_app"}
      else
        %{name: module_name, app: app_name}
      end
    rescue
      _ ->
        # Fallback if Mix.Project is not available
        %{name: "MyApp", app: "my_app"}
    end
  end

  defp get_module_file_path(module_name) do
    module_path_parts = module_name |> String.split(".") |> Enum.map(&Macro.underscore/1)
    "lib/#{Enum.join(module_path_parts, "/")}.ex"
  end

  defp create_swift_package(base_path, swift_path, nif_name, project_name, swiftler_path) do
    full_path = Path.join(base_path, swift_path)
    File.mkdir_p!(full_path)
    swift_target_name = Macro.camelize(nif_name)
    File.mkdir_p!("#{full_path}/Sources/#{swift_target_name}")

    # Use provided local path if given, otherwise use remote URL
    {swiftler_dependency, package_name} =
      if swiftler_path do
        # Convert relative path to absolute path from the Swift package's perspective
        absolute_swiftler_path = Path.expand(swiftler_path, base_path)
        relative_path = Path.relative_to(absolute_swiftler_path, full_path)
        # Get the directory name for the package reference
        dir_name = Path.basename(absolute_swiftler_path)
        {".package(path: \"#{relative_path}\")", dir_name}
      else
        {".package(url: \"https://github.com/tuist/swiftler.git\", branch: \"main\")", "swiftler"}
      end

    package_swift = """
    // swift-tools-version: 6.0
    import PackageDescription

    let package = Package(
        name: "#{project_name}Native",
        platforms: [.macOS(.v13)],
        products: [
            .library(
                name: "#{project_name}Native",
                type: .dynamic,
                targets: ["#{swift_target_name}"]
            )
        ],
        dependencies: [
            #{swiftler_dependency}
        ],
        targets: [
            .target(
                name: "#{swift_target_name}",
                dependencies: [
                    .product(name: "Swiftler", package: "#{package_name}")
                ]
            )
        ]
    )
    """

    package_file = "#{full_path}/Package.swift"
    File.write!(package_file, package_swift)
    Mix.shell().info("Created #{Path.relative_to(package_file, base_path)}")
  end

  defp create_swift_sources(base_path, swift_path, nif_name) do
    full_path = Path.join(base_path, swift_path)
    swift_target_name = Macro.camelize(nif_name)

    swift_source = """
    import Swiftler
    import Foundation

    #nifLibrary(name: "#{nif_name}", functions: [add(_:_:), multiply(_:_:), greet(_:)])

    @nif func add(_ a: Int, _ b: Int) -> Int {
        a + b
    }

    @nif func multiply(_ a: Int, _ b: Int) -> Int {
        a * b
    }

    @nif func greet(_ name: String) -> String {
        "Hello, \\(name) from Swift!"
    }
    """

    source_path = "#{full_path}/Sources/#{swift_target_name}/#{swift_target_name}.swift"
    File.write!(source_path, swift_source)
    Mix.shell().info("Created #{Path.relative_to(source_path, base_path)}")
  end

  defp create_elixir_module(base_path, module_name, nif_name, swift_path) do
    # Handle nested module names by creating proper directory structure
    module_path_parts = module_name |> String.split(".") |> Enum.map(&Macro.underscore/1)
    module_path = Path.join([base_path, "lib"] ++ module_path_parts) <> ".ex"

    # Create nested directories if needed
    module_dir = Path.dirname(module_path)
    File.mkdir_p!(module_dir)

    library_name =
      case swift_path do
        "native" -> "libswiftler"
        _ -> "lib#{nif_name}"
      end

    elixir_module = """
    defmodule #{module_name} do
      @moduledoc \"\"\"
      Swift NIF module for #{nif_name}.
      
      This module provides Elixir bindings for Swift functions compiled as NIFs.
      \"\"\"

      @on_load :load_nifs

      def load_nifs do
        :erlang.load_nif('./priv/#{library_name}', 0)
      end

      @doc \"\"\"
      Adds two integers.

      ## Examples

          iex> #{module_name}.add(5, 3)
          8

      \"\"\"
      def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)

      @doc \"\"\"
      Multiplies two integers.

      ## Examples

          iex> #{module_name}.multiply(4, 3)
          12

      \"\"\"
      def multiply(_a, _b), do: :erlang.nif_error(:nif_not_loaded)

      @doc \"\"\"
      Greets a person by name.

      ## Examples

          iex> #{module_name}.greet("World")
          "Hello, World from Swift!"

      \"\"\"
      def greet(_name), do: :erlang.nif_error(:nif_not_loaded)
    end
    """

    File.write!(module_path, elixir_module)
    Mix.shell().info("Created #{Path.relative_to(module_path, base_path)}")
  end
end
