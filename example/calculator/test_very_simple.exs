#!/usr/bin/env mix run

# Test the very simple string function
defmodule VerySimple do
  @on_load :load_nif
  
  def load_nif do
    path = Path.join([__DIR__, "priv/libCalculatorNative"])
    :erlang.load_nif(String.to_charlist(path), 0)
  end
  
  def very_simple_string do
    :erlang.nif_error(:nif_not_loaded)
  end
end

IO.puts "Loading module..."
VerySimple.load_nif()

IO.puts "Testing very_simple_string..."
result = VerySimple.very_simple_string()
IO.puts "Result: #{inspect(result)}"