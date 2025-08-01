# Simple test to isolate the string issue
IO.puts "Testing Calculator string functions..."

# First test that integer functions work
IO.puts "add(5, 3) = #{Calculator.add(5, 3)}"

# Now test the problematic string function
IO.puts "About to call greet..."
try do
  result = Calculator.greet("World")
  IO.puts "Success! greet returned: #{inspect result}"
rescue
  e ->
    IO.puts "Error: #{inspect e}"
    IO.puts Exception.format(:error, e, __STACKTRACE__)
end

IO.puts "Test complete"