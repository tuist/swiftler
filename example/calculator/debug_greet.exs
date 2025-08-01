#!/usr/bin/env elixir

Mix.install([])

Code.prepend_path("_build/test/lib/calculator/ebin")

defmodule DebugTest do
  def test_greet do
    IO.puts("About to call Calculator.greet...")
    result = Calculator.greet("World")
    IO.puts("Result: #{result}")
  rescue
    e -> IO.puts("Error: #{inspect(e)}")
  end
end

DebugTest.test_greet()