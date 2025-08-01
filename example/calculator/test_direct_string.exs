#!/usr/bin/env elixir

# Direct test of string functionality with more debugging
IO.puts "Starting direct string test..."

# First verify the library is loaded
case :erlang.module_loaded(Calculator) do
  true -> IO.puts "Calculator module is loaded"
  false -> 
    IO.puts "Calculator module not loaded, attempting to load..."
    Code.ensure_loaded(Calculator)
end

# Test if NIF is actually loaded
try do
  # Try integer function first
  result = Calculator.add(1, 1)
  IO.puts "Integer test successful: 1 + 1 = #{result}"
catch
  kind, error ->
    IO.puts "Integer test failed: #{kind} - #{inspect(error)}"
end

# Now test string function
IO.puts "\nTesting simple_string_test()..."
try do
  result = Calculator.simple_string_test()
  IO.puts "String test successful: #{inspect(result)}"
catch
  kind, error ->
    IO.puts "String test failed: #{kind} - #{inspect(error)}"
end

IO.puts "\nTest complete!"