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
    otp_app = Keyword.fetch!(opts, :otp_app)
    crate = Keyword.get(opts, :crate, "swiftler")
    load_data = Keyword.get(opts, :load_data, 0)

    quote do
      import Swiftler.Macros
      @before_compile Swiftler.Macros

      Module.register_attribute(__MODULE__, :swift_functions, accumulate: true)

      @swiftler_opts unquote(opts)
      @otp_app unquote(otp_app)
      @crate unquote(crate)
      @load_data unquote(load_data)

      # Trigger Swift compilation at compile time
      require Swiftler.Compiler
      @load_from Swiftler.Compiler.compile_crate(unquote(otp_app), unquote(crate), unquote(opts))

      @on_load :__swiftler_init__

      def __swiftler_init__ do
        # Load the compiled NIF
        load_path = @load_from |> to_charlist()

        case :erlang.load_nif(load_path, @load_data) do
          :ok ->
            :ok

          {:error, {:reload, _}} ->
            :ok

          {:error, reason} ->
            raise "Failed to load Swift NIF from #{load_path}: #{inspect(reason)}"
        end
      end
    end
  end
end
