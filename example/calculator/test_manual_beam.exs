#!/usr/bin/env elixir

IO.puts "Testing minimal functionality without macros..."

try do
  # Test integer function first - this should work
  result = Calculator.add(2, 3)
  IO.puts "add(2, 3) = #{result}"
  
  IO.puts "All done - integer functions work!"
rescue
  e ->
    IO.puts "Error: #{inspect(e)}"
    IO.puts Exception.format(:error, e, __STACKTRACE__)
end