defmodule Swiftler do
  @moduledoc """
  Swiftler allows you to call Swift code from Elixir using NIFs.

  This library provides macros and utilities to:
  - Define Swift functions that can be called from Elixir
  - Automatically generate NIF bindings
  - Compile Swift source code into loadable NIFs

  ## Usage

      defmodule MyModule do
        use Swiftler
        
        swift_function add(a: :int, b: :int) :: :int
        swift_function greet(name: :string) :: :string
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Swiftler.Macros
      @before_compile Swiftler.Macros

      Module.register_attribute(__MODULE__, :swift_functions, accumulate: true)
    end
  end
end
