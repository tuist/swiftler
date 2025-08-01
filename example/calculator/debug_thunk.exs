#!/usr/bin/env mix run

# Let's test which functions work
tests = [
  {:add, [1, 2], "Integer function"},
  {:is_prime, [7], "Bool function"},
  {:sqrt, [16.0], "Double function"},
  {:factorial, [5], "Integer function returning integer"},
  {:circle_area, [2.0], "Double function returning double"}
]

IO.puts("Testing non-string functions...")
for {func, args, desc} <- tests do
  try do
    result = apply(Calculator, func, args)
    IO.puts("✓ #{desc} - #{func}(#{Enum.join(args, ", ")}) = #{inspect(result)}")
  catch
    kind, error ->
      IO.puts("✗ #{desc} - #{func} failed: #{kind} - #{inspect(error)}")
  end
end

IO.puts("\nNow testing string functions...")
IO.puts("Testing simple_string_test()...")
try do
  result = Calculator.simple_string_test()
  IO.puts("✓ simple_string_test() = #{inspect(result)}")
catch
  kind, error ->
    IO.puts("✗ simple_string_test() failed: #{kind} - #{inspect(error)}")
end