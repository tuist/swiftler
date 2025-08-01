#!/usr/bin/env elixir

defmodule TestManualSimple do
  @on_load :load_nif
  
  def load_nif do
    path = Path.join([__DIR__, "native/.build/arm64-apple-macosx/release/libCalculatorNative"])
    :erlang.load_nif(String.to_charlist(path), 0)
  end
  
  def manual_simple_string_test do
    :erlang.nif_error(:nif_not_loaded)
  end
end

IO.puts "Loading test module..."
TestManualSimple.load_nif()

IO.puts "Testing manual_simple_string_test..."
result = TestManualSimple.manual_simple_string_test()
IO.puts "Result: #{inspect(result)}"