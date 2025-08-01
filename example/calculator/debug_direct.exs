#!/usr/bin/env elixir

Mix.install([])

Code.prepend_path("_build/test/lib/calculator/ebin")

defmodule DebugDirect do
  def test_direct do
    IO.puts("About to call direct_string_test...")
    result = :erlang.load_nif('./priv/calculator', 0)
    IO.puts("NIF load result: #{inspect(result)}")
    
    # Call the direct function
    result = :erlang.apply(:calculator_nif, :direct_string_test, [])
    IO.puts("Direct result: #{inspect(result)}")
  rescue
    e -> IO.puts("Error: #{inspect(e)}")
  end
end

DebugDirect.test_direct()