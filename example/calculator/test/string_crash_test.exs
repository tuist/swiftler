defmodule StringCrashTest do
  use ExUnit.Case

  test "greet function causes crash" do
    # This test is expected to crash - used for debugging
    result = Calculator.greet("World")
    assert result == "Hello, World! Welcome to Swiftler Calculator."
  end
end