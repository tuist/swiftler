defmodule Mix.Tasks.Compile.Swift do
  @moduledoc """
  Compiles Swift source files into NIFs.

  This task:
  1. Compiles Swift package using Swift Package Manager
  2. Generates dynamic library (.dylib/.so) with NIF exports
  3. Copies the compiled dynamic library to priv/ for loading
  4. Works with bundled Erlang headers (no system dependencies)
  5. Tracks source file changes and only recompiles when necessary
  """

  use Mix.Task.Compiler

  @recursive true
  @manifest ".swift_compile"
  @manifest_vsn 1

  @impl true
  def run(args) do
    config = Mix.Project.config()
    swift_opts = config[:swift_opts] || []
    manifest_path = manifest_path()
    
    # Check if we need to compile
    if needs_compilation?(manifest_path) do
      try do
        with :ok <- ensure_swift_available(),
             :ok <- ensure_native_directory(),
             sources = get_swift_sources(),
             :ok <- compile_with_spm(swift_opts, sources),
             :ok <- generate_dynamic_bindings() do
          # Write manifest after successful compilation
          write_manifest(manifest_path, sources)
          unless "--silent" in args do
            Mix.shell().info("Compiled Swift NIF")
          end
          {:ok, []}
        else
          {:error, reason} when is_binary(reason) ->
            Mix.shell().error("Swift compilation failed: #{reason}")
            {:error, []}

          {:error, reason} ->
            Mix.shell().error("Swift compilation failed: #{inspect(reason)}")
            {:error, []}

          error ->
            Mix.shell().error("Unexpected error during Swift compilation: #{inspect(error)}")
            {:error, []}
        end
      rescue
        exception ->
          Mix.shell().error("Exception during Swift compilation: #{Exception.message(exception)}")
          {:error, []}
      end
    else
      {:noop, []}
    end
  end

  @impl true
  def manifests, do: [manifest_path()]

  @impl true
  def clean() do
    File.rm_rf!("priv")
    File.rm(manifest_path())

    if File.exists?("native/.build") do
      System.cmd("swift", ["package", "clean"], cd: "native", stderr_to_stdout: true)
    end

    :ok
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

  defp compile_with_spm(swift_opts, _sources) do
    # Build the Swift package
    build_args = ["build", "-c", "release"] ++ swift_opts

    # Force recompilation using a trick similar to Rustler
    # Add a unique define flag to ensure fresh builds when needed
    timestamp = System.system_time(:millisecond)
    build_args = build_args ++ ["-Xswiftc", "-DSWIFTLER_BUILD_#{timestamp}"]

    # Determine build directory - use current directory if Package.swift exists, otherwise use native/
    build_dir = if File.exists?("Package.swift"), do: ".", else: "native"

    case System.cmd("swift", build_args, cd: build_dir, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Swift build failed: #{output}"}
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
          :ok ->
            generate_binding_instructions()
            :ok

          {:error, reason} ->
            {:error, "Failed to copy dynamic library: #{reason}"}
        end
    end
  end

  defp generate_binding_instructions do
    # No documentation file needed - keep it minimal
    :ok
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

  ## Manifest and change detection

  defp manifest_path do
    Path.join(Mix.Project.manifest_path(), @manifest)
  end

  defp needs_compilation?(manifest_path) do
    # Always compile if no manifest exists
    if not File.exists?(manifest_path) do
      true
    else
      # Check if the compiled library exists
      if not compiled_library_exists?() do
        true
      else
        # Read the manifest
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

  defp compiled_library_exists? do
    File.exists?("priv/libswiftler.dylib") or File.exists?("priv/libswiftler.so")
  end

  defp get_swift_sources do
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
    
    # Get modification times for all files
    (package_files ++ swift_files)
    |> Enum.map(fn path ->
      stat = File.stat!(path)
      {path, stat.mtime}
    end)
  end

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

  defp read_manifest(path) do
    case File.read(path) do
      {:ok, contents} ->
        try do
          manifest = :erlang.binary_to_term(contents)
          if manifest.vsn == @manifest_vsn do
            {:ok, manifest}
          else
            {:error, :version_mismatch}
          end
        rescue
          _ -> {:error, :invalid_manifest}
        end
      
      error -> error
    end
  end

  defp write_manifest(path, sources) do
    manifest = %{
      vsn: @manifest_vsn,
      sources: sources,
      timestamp: System.system_time()
    }
    
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, :erlang.term_to_binary(manifest))
  end
end
