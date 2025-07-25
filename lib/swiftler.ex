defmodule Swiftler do
  @moduledoc """
  Swiftler allows you to call Swift code from Elixir using NIFs.

  This library provides macros and utilities to:
  - Define Swift functions that can be called from Elixir
  - Automatically generate NIF bindings
  - Compile Swift source code into loadable NIFs

  ## Usage

      defmodule MyModule do
        use Swiftler, otp_app: :my_app
        
        swift_function add(a: :int, b: :int) :: :int
        swift_function greet(name: :string) :: :string
      end

  ## Options

  - `:otp_app` - The OTP application that contains the Swift code (required)
  - `:crate` - The name of the Swift package (defaults to "swiftler")
  - `:load_data` - Additional data to pass to NIF on_load (defaults to 0)
  - `:skip_compilation?` - Skip compilation of Swift code (defaults to false)
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      otp_app = Keyword.fetch!(opts, :otp_app)
      package = Keyword.get(opts, :crate, "swiftler")

      # Compile the Swift code at compile time and get configuration
      config = Swiftler.Compiler.compile_package(otp_app, package, opts)

      # Register all Swift files as external resources for recompilation tracking
      for resource <- config.external_resources do
        @external_resource resource
      end

      # Only set up NIF loading if we have a library
      if config.lib do
        @load_from config.load_from
        @load_data config.load_data
        @package config.package_name

        @before_compile Swiftler
      end

      # Always import macros regardless of compilation status
      import Swiftler.Macros
      @before_compile Swiftler.Macros

      Module.register_attribute(__MODULE__, :swift_functions, accumulate: true)

      @swiftler_opts opts
      @otp_app otp_app
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @on_load :__swiftler_init__

      def __swiftler_init__ do
        # Load the compiled NIF
        load_path = @load_from |> to_charlist()

        # Debug logging in CI
        if System.get_env("CI") do
          IO.puts(
            "Swiftler runtime: OS=#{inspect(:os.type())}, load_from=#{@load_from}, load_path=#{inspect(load_path)}"
          )
        end

        case :erlang.load_nif(load_path, @load_data) do
          :ok ->
            :ok

          {:error, {:reload, _}} ->
            :ok

          {:error, reason} ->
            raise "Failed to load Swift NIF from #{@load_from}: #{inspect(reason)}"
        end
      end
    end
  end
end
