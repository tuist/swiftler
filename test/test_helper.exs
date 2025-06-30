ExUnit.start()

defmodule SwiftlerTestHelper do
  @moduledoc """
  Helper functions for Swiftler tests.
  """

  def ensure_swift_compiled do
    # Check if Swift compiler is available
    case System.find_executable("swift") do
      nil ->
        IO.puts("Warning: Swift compiler not found. Some tests will be skipped.")
        false

      _ ->
        # Attempt to compile Swift sources
        case Mix.Tasks.Swift.Compile.run([]) do
          :ok -> true
          {:error, _} -> false
        end
    end
  end

  def skip_if_swift_not_available(context) do
    if ensure_swift_compiled() do
      context
    else
      ExUnit.configure(exclude: [:requires_swift])
      context
    end
  end
end
