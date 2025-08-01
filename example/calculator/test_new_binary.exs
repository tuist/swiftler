#!/usr/bin/env mix run

# Test the new binary function
defmodule TestNewBinary do
  @on_load :load_nif
  
  def load_nif do
    # Use absolute path to dylib
    path = Path.join([__DIR__, "native/.build/arm64-apple-macosx/release/libCalculatorNative"])
    :erlang.load_nif(String.to_charlist(path), 0)
  end
  
  def test_new_binary do
    :erlang.nif_error(:nif_not_loaded)
  end
end

IO.puts "Loading test module..."
TestNewBinary.load_nif()

IO.puts "Testing test_new_binary..."
result = TestNewBinary.test_new_binary()
IO.puts "Result: #{inspect(result)}"