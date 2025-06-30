defmodule Examples.MathTest do
  use ExUnit.Case

  # Note: These tests verify the Swift static library integration
  # The functions return placeholder values until static linking is implemented

  describe "Examples.Math static linking placeholders" do
    test "add/2 indicates static linking needed" do
      result = Examples.Math.add(5, 3)
      assert {:error, :static_linking_required, "add_swift", [:a, :b]} = result
    end

    test "fibonacci_sequence/1 function exists" do
      result = Examples.Math.fibonacci_sequence(5)
      assert is_list(result)
    end

    test "primes_up_to/1 function exists" do
      result = Examples.Math.primes_up_to(10)
      assert is_list(result)
    end

    test "greet/1 indicates static linking needed" do
      result = Examples.Math.greet("World")
      assert {:error, :static_linking_required, "greet_swift", [:name]} = result
    end

    test "calculate_circle_area/1 indicates static linking needed" do
      result = Examples.Math.calculate_circle_area(5.0)
      assert {:error, :static_linking_required, "calculate_circle_area_swift", [:radius]} = result
    end
  end
end
