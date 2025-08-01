#!/usr/bin/env mix run

# Test just the simplest operations
IO.puts "Testing add (integer)..."
result = Calculator.add(1, 2)
IO.puts "add(1, 2) = #{result}"

IO.puts "\nTesting is_prime (bool)..."
result = Calculator.is_prime(7)
IO.puts "is_prime(7) = #{result}"

IO.puts "\nTesting sqrt (double)..."
result = Calculator.sqrt(16.0)
IO.puts "sqrt(16.0) = #{result}"

IO.puts "\nAbout to test simple_string_test (string)..."
IO.puts "Calling simple_string_test()..."
result = Calculator.simple_string_test()
IO.puts "simple_string_test() = #{inspect(result)}"

IO.puts "\nAll tests complete!"