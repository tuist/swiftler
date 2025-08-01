#!/usr/bin/env elixir

defmodule DirectThunkTest do
  @on_load :load_nif
  
  def load_nif do
    path = Path.join([__DIR__, "native/.build/arm64-apple-macosx/release/libCalculatorNative"])
    :erlang.load_nif(String.to_charlist(path), 0)
  end
  
  def direct_simple_string_test do
    :erlang.nif_error(:nif_not_loaded)
  end
end

IO.puts "Loading direct thunk test module..."
DirectThunkTest.load_nif()

IO.puts "Testing direct_simple_string_test..."
result = DirectThunkTest.direct_simple_string_test()
IO.puts "Result: #{inspect(result)}"