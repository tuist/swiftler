IO.puts "Testing NIF functions..."

# Test arithmetic functions first
IO.puts "Testing add: #{inspect Calculator.add(5, 3)}"
IO.puts "Testing multiply: #{inspect Calculator.multiply(7, 6)}"

# Test boolean function
IO.puts "Testing is_prime: #{inspect Calculator.is_prime(17)}"

# Now test the problematic string function
IO.puts "About to test greet function..."
try do
  result = Calculator.greet("Test")
  IO.puts "Greet result: #{inspect result}"
rescue
  e ->
    IO.puts "Error in greet: #{inspect e}"
    IO.puts Exception.format(:error, e, __STACKTRACE__)
end