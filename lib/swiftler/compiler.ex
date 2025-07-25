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
      # Check if we have a pre-built library first
      if has_prebuilt_library?() do
        IO.puts("Using pre-built Swift library")
        use_prebuilt_library()
      else
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

  defp has_prebuilt_library? do
    # Check if there's a pre-built library in the prebuilt directory
    prebuilt_dir = "prebuilt"
    
    if File.exists?(prebuilt_dir) do
      extension = case :os.type() do
        {:unix, :darwin} -> ".dylib"
        _ -> ".so"
      end
      
      File.ls!(prebuilt_dir)
      |> Enum.any?(fn file -> String.ends_with?(file, extension) end)
    else
      false
    end
  end

  defp use_prebuilt_library do
    prebuilt_dir = "prebuilt"
    File.mkdir_p!("priv")
    
    extension = case :os.type() do
      {:unix, :darwin} -> ".dylib"
      _ -> ".so"
    end
    
    # Copy all matching libraries from prebuilt to priv
    File.ls!(prebuilt_dir)
    |> Enum.filter(fn file -> String.ends_with?(file, extension) end)
    |> Enum.each(fn file ->
      source = Path.join(prebuilt_dir, file)
      target = Path.join("priv", file)
      File.cp!(source, target)
      
      # Create symlink for macOS if needed
      if extension == ".dylib" do
        so_target = String.replace_suffix(target, ".dylib", ".so")
        File.rm(so_target)
        File.ln_s(Path.basename(target), so_target)
      end
    end)
    
    :ok
  end

  defp compiled_library_exists? do
    # Check if the specific library exists in priv/
    if File.exists?("priv") do
      # Look for the expected library name based on Package.swift
      package_name = get_package_name()
      
      File.ls!("priv")
      |> Enum.any?(fn file ->
        # Check for lib{PackageName}.dylib or lib{PackageName}.so
        (String.starts_with?(file, "lib#{package_name}") and
          (String.ends_with?(file, ".dylib") or String.ends_with?(file, ".so")))
      end)
    else
      false
    end
  end

  defp get_package_name do
    # Extract package name from Package.swift
    package_path = if File.exists?("Package.swift"), do: "Package.swift", else: "native/Package.swift"
    
    if File.exists?(package_path) do
      content = File.read!(package_path)
      
      # Find the library product name
      case Regex.run(~r/\.library\s*\(\s*name:\s*"([^"]+)"/, content) do
        [_, name] -> name
        _ -> "swiftler"
      end
    else
      "swiftler"
    end
  end

  defp needs_compilation? do
    # Always compile if no library exists
    if not compiled_library_exists?() do
      true
    else
      # Check if any source files have changed
      manifest_path = Path.join(Mix.Project.manifest_path(), ".swift_compile")
      
      if not File.exists?(manifest_path) do
        true
      else
        case read_manifest(manifest_path) do
          {:ok, manifest} ->
            # Check if any source files have changed
            current_sources = get_swift_sources()
            sources_changed?(manifest.sources, current_sources)
          
          {:error, _} ->
            # If we can't read the manifest, recompile
            true
        end
      end
    end
  end

  defp compile_swift_directly do
    with :ok <- ensure_swift_available(),
         :ok <- ensure_native_directory(),
         sources = get_swift_sources(),
         :ok <- compile_with_spm(),
         :ok <- generate_dynamic_bindings() do
      # Write manifest after successful compilation
      write_manifest(sources)
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
    build_args = ["build", "-c", "release", "--product", get_package_name()]

    # Determine build directory - use current directory if Package.swift exists, otherwise use native/
    build_dir = if File.exists?("Package.swift"), do: ".", else: "native"

    # Run Swift build command with a reasonable timeout
    # Note: First builds can take 5-10+ minutes due to SwiftSyntax compilation
    timeout = if System.get_env("CI"), do: 600_000, else: 300_000  # 10 min in CI, 5 min locally
    
    # Check if we're in CI or if the user wants verbose output
    unless System.get_env("MIX_QUIET") == "true" do
      IO.puts("Building Swift package (this may take several minutes on first build due to SwiftSyntax)...")
    end
    
    task = Task.async(fn ->
      System.cmd("swift", build_args, cd: build_dir, stderr_to_stdout: true)
    end)
    
    case Task.await(task, timeout) do
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

  # Get Swift sources with modification times
  defp get_swift_sources do
    # Get sources from the current project
    local_sources = get_swift_sources_paths()
    
    # Also include Swiftler library sources that affect the generated code
    swiftler_root = find_swiftler_root()
    swiftler_sources = if swiftler_root do
      # Include macro sources and support files that affect code generation
      [
        Path.join([swiftler_root, "Sources", "SwiftlerMacros", "SwiftlerMacros.swift"]),
        Path.join([swiftler_root, "Sources", "Swiftler", "Swiftler.swift"]),
        Path.join([swiftler_root, "Sources", "SwiftlerSupport", "**", "*.swift"])
      ]
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.filter(&File.exists?/1)
    else
      []
    end
    
    (local_sources ++ swiftler_sources)
    |> Enum.map(fn path ->
      stat = File.stat!(path)
      {path, stat.mtime}
    end)
  end

  # Find the Swiftler library root directory
  defp find_swiftler_root do
    # When running in the example, Swiftler is at ../../..
    # When running as a dependency, it would be in deps/swiftler
    cond do
      # Running in example/calculator
      File.exists?("../../../Package.swift") and File.exists?("../../../Sources/Swiftler") ->
        Path.expand("../../..")
      
      # Running as a dependency
      File.exists?("deps/swiftler/Package.swift") ->
        "deps/swiftler"
        
      # Default case - we're in the Swiftler project itself
      File.exists?("Package.swift") and File.exists?("Sources/Swiftler") ->
        "."
        
      true ->
        nil
    end
  end

  # Check if sources have changed
  defp sources_changed?(old_sources, new_sources) do
    # Convert to maps for easier comparison
    old_map = Map.new(old_sources)
    new_map = Map.new(new_sources)

    # Check if any files were added or removed
    if Map.keys(old_map) != Map.keys(new_map) do
      true
    else
      # Check if any file was modified
      Enum.any?(new_map, fn {path, mtime} ->
        old_mtime = Map.get(old_map, path)
        old_mtime != mtime
      end)
    end
  end

  # Read manifest file
  defp read_manifest(path) do
    case File.read(path) do
      {:ok, contents} ->
        try do
          manifest = :erlang.binary_to_term(contents)
          {:ok, manifest}
        rescue
          _ -> {:error, :invalid_manifest}
        end

      error ->
        error
    end
  end

  # Write manifest file
  defp write_manifest(sources) do
    manifest_path = Path.join(Mix.Project.manifest_path(), ".swift_compile")
    
    manifest = %{
      sources: sources,
      timestamp: System.system_time()
    }

    File.mkdir_p!(Path.dirname(manifest_path))
    File.write!(manifest_path, :erlang.term_to_binary(manifest))
  end
end
