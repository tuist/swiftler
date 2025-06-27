defmodule SwiftlerTest do
  use ExUnit.Case
  doctest Swiftler

  describe "Swiftler module" do
    test "provides basic functionality" do
      # Test that the module can be loaded
      assert Code.ensure_loaded?(Swiftler)
    end
  end
end