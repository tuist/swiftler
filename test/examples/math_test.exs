defmodule Examples.MathTest do
  use ExUnit.Case

  # Note: These tests verify the function definitions exist
  # The functions will raise :nif_not_loaded until a Swift library is loaded

  describe "Examples.Math function definitions" do
    test "add/2 raises nif_not_loaded" do
      assert_raise ErlangError, ~r/nif_not_loaded/, fn ->
        Examples.Math.add(5, 3)
      end
    end

    test "fibonacci_sequence/1 function exists" do
      assert_raise ErlangError, ~r/nif_not_loaded/, fn ->
        Examples.Math.fibonacci_sequence(5)
      end
    end

    test "primes_up_to/1 function exists" do
      assert_raise ErlangError, ~r/nif_not_loaded/, fn ->
        Examples.Math.primes_up_to(10)
      end
    end

    test "greet/1 raises nif_not_loaded" do
      assert_raise ErlangError, ~r/nif_not_loaded/, fn ->
        Examples.Math.greet("World")
      end
    end

    test "calculate_circle_area/1 raises nif_not_loaded" do
      assert_raise ErlangError, ~r/nif_not_loaded/, fn ->
        Examples.Math.calculate_circle_area(5.0)
      end
    end
  end
end
