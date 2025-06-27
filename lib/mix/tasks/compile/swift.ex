defmodule Mix.Tasks.Compile.Swift do
  @moduledoc """
  Compiles Swift source files into NIFs.
  
  This task:
  1. Finds all Swift source files in native/
  2. Generates C bridge code for NIFs  
  3. Compiles Swift code with the C bridge
  4. Places the compiled .so/.dylib in priv/
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
           :ok <- generate_static_bindings() do
        Mix.shell().info("Generated Swift static library and bindings")
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
    if not File.exists?("native/Package.swift") do
      {:error, "native/Package.swift not found. Please create a Swift package in the native/ directory."}
    else
      File.mkdir_p!("priv")
      :ok
    end
  end
  
  defp compile_with_spm(swift_opts) do
    # Build the Swift package
    build_args = ["build", "-c", "release"] ++ swift_opts
    
    case System.cmd("swift", build_args, cd: "native", stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Swift build failed: #{output}"}
    end
  end
  
  defp generate_static_bindings do
    # Find the built static library
    build_path = "native/.build/release"
    static_lib = find_file_with_extension(build_path, ".a")
    
    case static_lib do
      nil -> {:error, "Could not find compiled static library (.a) in #{build_path}"}
      static_lib_path ->
        # Copy static library to priv for linking
        File.mkdir_p!("priv")
        target_path = Path.join("priv", "libswiftler.a")
        
        case File.cp(static_lib_path, target_path) do
          :ok -> 
            generate_binding_instructions()
            :ok
          {:error, reason} -> 
            {:error, "Failed to copy static library: #{reason}"}
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