#!/usr/bin/env elixir

# Load the NIF directly
path = Path.join([__DIR__, "priv", "libCalculatorNative"])
case :erlang.load_nif(path, 0) do
  :ok -> IO.puts("NIF loaded successfully")
  {:error, reason} -> IO.puts("Failed to load NIF: #{inspect(reason)}")
end

# Test integer function
IO.puts("\nTesting add(2, 3)...")
try do
  result = :erlang.nif_call(:add, [2, 3])
  IO.puts("Result: #{result}")
rescue
  e -> IO.puts("Error: #{inspect(e)}")
end

# Call using the NIF functions directly
defmodule DirectTest do
  def test_functions do
    # These functions should be available after NIF load
    IO.puts("\nTesting Calculator functions...")
    
    # Test add
    result = apply(:erlang, :nif_call, [:___swiftler_nif_thunk_add, [2, 3]])
    IO.puts("add(2, 3) = #{inspect(result)}")
    
    # Test greet
    result = apply(:erlang, :nif_call, [:___swiftler_nif_thunk_greet, ["World"]])
    IO.puts("greet(\"World\") = #{inspect(result)}")
  end
end

DirectTest.test_functions()