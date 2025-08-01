#!/usr/bin/env elixir

# Test using the manual NIF function that we know works
defmodule ManualTest do
  @on_load :load_nif
  
  def load_nif do
    path = Path.join([__DIR__, "native/.build/arm64-apple-macosx/release/libCalculatorNative"])
    :erlang.load_nif(String.to_charlist(path), 0)
  end
  
  def working_greet do
    :erlang.nif_error(:nif_not_loaded)
  end
end

IO.puts "Loading manual test module..."
ManualTest.load_nif()

IO.puts "Testing working_greet..."
try do
  result = ManualTest.working_greet()
  IO.puts "Result: #{inspect(result)}"
catch
  kind, error ->
    IO.puts "Error: #{kind} - #{inspect(error)}"
end