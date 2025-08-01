#!/usr/bin/env mix run

# Direct test of the working_greet function we know works
IO.puts "Testing working_greet function..."

result = Calculator.greet("Test")
IO.puts "Result: #{inspect(result)}"

IO.puts "\nNow testing simple_string_test..."
result2 = Calculator.simple_string_test()
IO.puts "Result2: #{inspect(result2)}"