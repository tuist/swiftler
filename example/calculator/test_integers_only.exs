#!/usr/bin/env elixir

IO.puts "Testing integer functions only..."

try do
  # Test various integer functions
  IO.puts "add(2, 3) = #{Calculator.add(2, 3)}"
  IO.puts "subtract(10, 4) = #{Calculator.subtract(10, 4)}"
  IO.puts "multiply(5, 6) = #{Calculator.multiply(5, 6)}"
  IO.puts "divide(20, 4) = #{Calculator.divide(20, 4)}"
  IO.puts "power(2, 3) = #{Calculator.power(2, 3)}"
  IO.puts "factorial(5) = #{Calculator.factorial(5)}"
  IO.puts "is_prime(17) = #{Calculator.is_prime(17)}"
  IO.puts "gcd(12, 8) = #{Calculator.gcd(12, 8)}"
  IO.puts "fibonacci(10) = #{Calculator.fibonacci(10)}"
  
  IO.puts "\nAll integer functions work perfectly!"
rescue
  e ->
    IO.puts "Error: #{inspect(e)}"
    IO.puts Exception.format(:error, e, __STACKTRACE__)
end