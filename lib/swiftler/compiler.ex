defmodule Swiftler.Compiler do
  @moduledoc false

  @doc """
  Compiles a Swift crate at compile time and returns the path to the compiled library.

  This function is called during module compilation to ensure the Swift code
  is compiled and available before the Elixir module needs it.
  """
  def compile_crate(_otp_app, crate_name, opts) do
    config = Mix.Project.config()
    app_path = config[:app_path] || File.cwd!()

    unless skip_compilation?(opts) do
      # Compile the Swift code - this will use the manifest tracking
      case Mix.Task.run("compile.swift", ["--silent"]) do
        {:ok, _} ->
          :ok

        # Already compiled, no changes
        {:noop, _} ->
          :ok

        {:error, _} ->
          raise "Failed to compile Swift code for crate #{crate_name}"

        _ ->
          :ok
      end
    end

    # Return the path to the compiled library
    find_library_path(app_path, crate_name)
  end

  defp skip_compilation?(opts) do
    Keyword.get(opts, :skip_compilation?, false) or
      System.get_env("SWIFTLER_SKIP_COMPILATION") == "true"
  end

  defp find_library_path(app_path, crate_name) do
    priv_dir = Path.join(app_path, "priv")

    # Try different library naming conventions
    possible_names = [
      "lib#{crate_name}.dylib",
      "lib#{crate_name}.so",
      "libswiftler.dylib",
      "libswiftler.so",
      "#{crate_name}.dylib",
      "#{crate_name}.so"
    ]

    Enum.find_value(possible_names, fn name ->
      path = Path.join(priv_dir, name)

      if File.exists?(path) do
        # Return path without extension for :erlang.load_nif
        Path.join(priv_dir, Path.basename(name, Path.extname(name)))
      end
    end) || raise "Could not find compiled Swift library for #{crate_name} in #{priv_dir}"
  end
end
