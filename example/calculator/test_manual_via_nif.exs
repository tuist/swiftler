#!/usr/bin/env mix run

# Test the manual implementation via direct NIF call
result = :erlang.apply_nif(
  :erlang.load_nif(
    String.to_charlist(Path.join([__DIR__, "native/.build/arm64-apple-macosx/release/libCalculatorNative"])), 
    0
  ),
  :manual_simple_string_test,
  []
)

IO.puts "Result: #{inspect(result)}"