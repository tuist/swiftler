defmodule Swiftler.Compiler do
  @moduledoc false

  defmodule Config do
    @moduledoc false
    defstruct [
      :load_from,
      :load_data,
      :external_resources,
      :lib,
      :package_name
    ]
  end

  @doc """
  Compiles a Swift package at compile time and returns configuration for the NIF.

  This function is called during module compilation to ensure the Swift code
  is compiled and available before the Elixir module needs it.
  """
  def compile_package(_otp_app, package_name, opts) do
    config = Mix.Project.config()
    app_path = config[:app_path] || File.cwd!()

    unless skip_compilation?(opts) do
      # Compile Swift if library doesn't exist or if sources have changed
      if needs_compilation?() do
        case compile_swift_directly() do
          :ok ->
            :ok

          {:error, reason} ->
            raise "Failed to compile Swift code for package #{package_name}: #{reason}"
        end
      end
    end

    # Get Swift source files for external resource tracking
    external_resources = get_swift_sources_paths()

    # Return configuration struct
    %Config{
      load_from: find_library_path(app_path, package_name),
      load_data: Keyword.get(opts, :load_data, 0),
      external_resources: external_resources,
      lib: !skip_compilation?(opts),
      package_name: package_name
    }
  end

  defp skip_compilation?(opts) do
    Keyword.get(opts, :skip_compilation?, false) or
      System.get_env("SWIFTLER_SKIP_COMPILATION") == "true"
  end

  defp compiled_library_exists? do
    File.exists?("priv/libswiftler.dylib") or File.exists?("priv/libswiftler.so")
  end

  defp needs_compilation? do
    # Always compile if no library exists
    not compiled_library_exists?()
  end

  defp compile_swift_directly do
    with :ok <- ensure_swift_available(),
         :ok <- ensure_native_directory(),
         :ok <- compile_with_spm(),
         :ok <- generate_dynamic_bindings() do
      :ok
    else
      error -> error
    end
  end

  defp ensure_swift_available do
    case System.find_executable("swift") do
      nil -> {:error, "Swift compiler not found. Please install Swift."}
      _ -> :ok
    end
  end

  defp ensure_native_directory do
    # For consumer projects, they should have their own Package.swift in a subdirectory
    # For the Swiftler package itself, Package.swift is at the root
    if File.exists?("Package.swift") or File.exists?("native/Package.swift") do
      File.mkdir_p!("priv")
      :ok
    else
      {:error,
       "Package.swift not found. Please create a Swift package or use Swiftler in a subdirectory."}
    end
  end

  defp compile_with_spm do
    # Build the Swift package
    build_args = ["build", "-c", "release"]

    # Force recompilation using a trick similar to Rustler
    # Add a unique define flag to ensure fresh builds when needed
    timestamp = System.system_time(:millisecond)
    build_args = build_args ++ ["-Xswiftc", "-DSWIFTLER_BUILD_#{timestamp}"]

    # Determine build directory - use current directory if Package.swift exists, otherwise use native/
    build_dir = if File.exists?("Package.swift"), do: ".", else: "native"

    # Use Task.async with timeout to prevent hanging on SwiftSyntax compilation during development
    # Default 30 seconds, but configurable via environment variable
    timeout = System.get_env("SWIFTLER_BUILD_TIMEOUT", "30000") |> String.to_integer()

    task =
      Task.async(fn ->
        System.cmd("swift", build_args, cd: build_dir, stderr_to_stdout: true)
      end)

    case Task.yield(task, timeout) do
      {:ok, {_output, 0}} ->
        :ok

      {:ok, {output, _}} ->
        {:error, "Swift build failed: #{output}"}

      nil ->
        Task.shutdown(task, :brutal_kill)

        {:error,
         "Swift build timed out (#{div(timeout, 1000)}s). This usually happens when compiling SwiftSyntax for the first time. Please run 'mix swift.compile' manually."}
    end
  end

  defp generate_dynamic_bindings do
    # Find the built dynamic library
    build_dir = if File.exists?("Package.swift"), do: ".", else: "native"
    build_path = "#{build_dir}/.build/release"

    # Look for dynamic library (.dylib on macOS, .so on Linux)
    dynamic_lib =
      find_file_with_extension(build_path, ".dylib") ||
        find_file_with_extension(build_path, ".so")

    case dynamic_lib do
      nil ->
        {:error, "Could not find compiled dynamic library (.dylib/.so) in #{build_path}"}

      dynamic_lib_path ->
        # Copy dynamic library to priv for NIF loading
        File.mkdir_p!("priv")

        # Determine target filename based on source
        source_filename = Path.basename(dynamic_lib_path)

        target_filename =
          case Path.extname(source_filename) do
            ".dylib" -> "libswiftler.dylib"
            ".so" -> "libswiftler.so"
            _ -> "libswiftler.so"
          end

        target_path = Path.join("priv", target_filename)

        case File.cp(dynamic_lib_path, target_path) do
          :ok -> :ok
          {:error, reason} -> {:error, "Failed to copy dynamic library: #{reason}"}
        end
    end
  end

  defp find_file_with_extension(dir, extension) do
    if File.exists?(dir) do
      File.ls!(dir)
      |> Enum.find(fn file -> String.ends_with?(file, extension) end)
      |> case do
        nil -> nil
        file -> Path.join(dir, file)
      end
    else
      nil
    end
  end

  defp find_library_path(app_path, package_name) do
    priv_dir = Path.join(app_path, "priv")

    # Try different library naming conventions
    possible_names = [
      "lib#{package_name}.dylib",
      "lib#{package_name}.so",
      "libswiftler.dylib",
      "libswiftler.so",
      "#{package_name}.dylib",
      "#{package_name}.so"
    ]

    Enum.find_value(possible_names, fn name ->
      path = Path.join(priv_dir, name)

      if File.exists?(path) do
        # Return path without extension for :erlang.load_nif
        Path.join(priv_dir, Path.basename(name, Path.extname(name)))
      end
    end) || Path.join(priv_dir, "libswiftler")
  end

  defp get_swift_sources_paths do
    # Find all Swift source files and Package.swift
    source_dir = if File.exists?("Package.swift"), do: ".", else: "native"

    package_swift = Path.join(source_dir, "Package.swift")
    sources_dir = Path.join(source_dir, "Sources")

    swift_files =
      if File.exists?(sources_dir) do
        Path.wildcard(Path.join([sources_dir, "**", "*.swift"]))
      else
        []
      end

    # Include Package.swift and Package.resolved if they exist
    package_files =
      [package_swift, Path.join(source_dir, "Package.resolved")]
      |> Enum.filter(&File.exists?/1)

    # Return all Swift-related files
    package_files ++ swift_files
  end
end
