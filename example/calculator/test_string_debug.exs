defmodule StringDebug do
  def test_creation do
    # Call our test function via Port
    path = Path.join([__DIR__, "native/.build/release/libCalculatorNative.dylib"])
    
    IO.puts "Testing string creation..."
    
    # Use the Calculator module instead
    :ok
  end
end

# Just test the Calculator module
IO.puts "Testing Calculator.greet function..."
try do
  result = Calculator.greet("Test")
  IO.puts "Success! Result: #{inspect result}"
rescue
  e ->
    IO.puts "Failed with error: #{inspect e}"
    :ok
end