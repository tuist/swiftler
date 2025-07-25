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

    # Find library path
    load_from = find_library_path(app_path, package_name)

    # Log for debugging - always log in CI
    if System.get_env("CI") || System.get_env("DEBUG_SWIFTLER") do
      IO.puts(
        "Swiftler compile-time: OS=#{inspect(:os.type())}, app_path=#{app_path}, package_name=#{package_name}, load_from=#{load_from}"
      )
    end

    # Return configuration struct
    %Config{
      load_from: load_from,
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
    # Check if any dynamic library exists in priv/
    if File.exists?("priv") do
      File.ls!("priv")
      |> Enum.any?(fn file ->
        String.ends_with?(file, ".dylib") or String.ends_with?(file, ".so")
      end)
    else
      false
    end
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

    # Run Swift build command
    case System.cmd("swift", build_args, cd: build_dir, stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, _} ->
        {:error, "Swift build failed: #{output}"}
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

        # Keep the original filename from Swift Package Manager
        target_filename = source_filename

        target_path = Path.join("priv", target_filename)

        case File.cp(dynamic_lib_path, target_path) do
          :ok ->
            # Create symlink for macOS Erlang NIF loader bug
            # Erlang on macOS looks for .so files even though it should look for .dylib
            if String.ends_with?(target_path, ".dylib") do
              so_path = String.replace_suffix(target_path, ".dylib", ".so")
              # Remove existing symlink if it exists
              File.rm(so_path)
              # Create symlink from .so to .dylib
              case File.ln_s(Path.basename(target_path), so_path) do
                :ok ->
                  :ok

                # Symlink already exists
                {:error, :eexist} ->
                  :ok

                {:error, reason} ->
                  IO.warn("Failed to create .so symlink: #{reason}")
                  :ok
              end
            end

            :ok

          {:error, reason} ->
            {:error, "Failed to copy dynamic library: #{reason}"}
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

    # On macOS, only look for .dylib; on Linux, only look for .so
    extension =
      case :os.type() do
        {:unix, :darwin} -> ".dylib"
        _ -> ".so"
      end

    # Try different library naming conventions with the correct extension
    possible_names = [
      "lib#{package_name}#{extension}",
      "libswiftler#{extension}",
      "#{package_name}#{extension}"
    ]

    # First try the expected names
    found =
      Enum.find_value(possible_names, fn name ->
        path = Path.join(priv_dir, name)

        if File.exists?(path) do
          # For :erlang.load_nif, we need to pass the path without extension
          # BUT only if the file actually exists with the correct extension
          # This ensures we're loading the right file
          Path.join(priv_dir, Path.basename(name, extension))
        end
      end)

    # If not found, look for any dynamic library in priv
    found || find_any_dynamic_library(priv_dir) || Path.join(priv_dir, "libswiftler")
  end

  defp find_any_dynamic_library(priv_dir) do
    if File.exists?(priv_dir) do
      # Only look for the correct extension for the current platform
      extension =
        case :os.type() do
          {:unix, :darwin} -> ".dylib"
          _ -> ".so"
        end

      libs =
        File.ls!(priv_dir)
        |> Enum.filter(fn file ->
          String.ends_with?(file, extension)
        end)

      case libs do
        [lib | _] ->
          # Return path without extension for :erlang.load_nif
          # Use the specific extension we found
          Path.join(priv_dir, Path.basename(lib, extension))

        [] ->
          nil
      end
    else
      nil
    end
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
