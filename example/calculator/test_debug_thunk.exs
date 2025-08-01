#!/usr/bin/env mix run

# Test the debug thunk directly
defmodule DebugThunk do
  @on_load :load_nif
  
  def load_nif do
    path = Path.join([__DIR__, "native/.build/arm64-apple-macosx/release/libCalculatorNative"])
    :erlang.load_nif(String.to_charlist(path), 0)
  end
  
  def debug_thunk_simple_string_test do
    :erlang.nif_error(:nif_not_loaded)
  end
end

IO.puts "Loading debug module..."
DebugThunk.load_nif()

IO.puts "Testing debug_thunk_simple_string_test..."
result = DebugThunk.debug_thunk_simple_string_test()
IO.puts "Result: #{inspect(result)}"