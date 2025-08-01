defmodule TestManualGreet do
  @on_load :load_nif

  def load_nif do
    path = Path.join([__DIR__, "native/.build/release/libCalculatorNative"])
    case :erlang.load_nif(String.to_charlist(path), 0) do
      :ok -> :ok
      {:error, {:bad_lib, _}} -> 
        # Expected - module name mismatch
        :ok
      {:error, reason} ->
        IO.puts "Failed to load NIF: #{inspect(reason)}"
        :ok
    end
  end
  
  # This won't work due to module name mismatch, but let's try the FFI approach
  def test_manual do
    # We'll use Port instead
    :ok
  end
end

# Instead, let's test by calling the actual Calculator module
# but first rebuild to export our manual function
IO.puts "Testing manual greet implementation..."

# The manual function is in the library, but we need to access it
# Let's check if it's exported
case System.cmd("nm", ["-g", "native/.build/release/libCalculatorNative.dylib"], cd: ".") do
  {output, 0} ->
    if String.contains?(output, "manual_greet_thunk") do
      IO.puts "Found manual_greet_thunk in exports"
    else
      IO.puts "manual_greet_thunk not found in exports"
    end
  _ ->
    IO.puts "Failed to check exports"
end

# Now test the regular greet function
IO.puts "\nTesting regular greet function:"
try do
  result = Calculator.greet("Test")
  IO.puts "Success: #{inspect result}"
rescue
  e ->
    IO.puts "Error: #{inspect e}"
end