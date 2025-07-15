defmodule Mix.Tasks.Compile.Swift do
  @moduledoc """
  Compiles Swift source files into NIFs.

  This task:
  1. Compiles Swift package using Swift Package Manager
  2. Generates dynamic library (.dylib/.so) with NIF exports
  3. Copies the compiled dynamic library to priv/ for loading
  4. Works with bundled Erlang headers (no system dependencies)
  """

  use Mix.Task.Compiler

  @recursive true
  @manifest "compile.swift"

  def run(_args) do
    config = Mix.Project.config()
    swift_opts = config[:swift_opts] || []

    try do
      with :ok <- ensure_swift_available(),
           :ok <- ensure_native_directory(),
           :ok <- compile_with_spm(swift_opts),
           :ok <- generate_dynamic_bindings() do
        Mix.shell().info("Generated Swift dynamic library and bindings")
        :ok
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
  end

  def clean() do
    File.rm_rf!("priv")

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

  defp compile_with_spm(swift_opts) do
    # Build the Swift package
    build_args = ["build", "-c", "release"] ++ swift_opts
    
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
    dynamic_lib = find_file_with_extension(build_path, ".dylib") || 
                  find_file_with_extension(build_path, ".so")

    case dynamic_lib do
      nil ->
        {:error, "Could not find compiled dynamic library (.dylib/.so) in #{build_path}"}

      dynamic_lib_path ->
        # Copy dynamic library to priv for NIF loading
        File.mkdir_p!("priv")
        
        # Determine target filename based on source
        source_filename = Path.basename(dynamic_lib_path)
        target_filename = case Path.extname(source_filename) do
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
end
