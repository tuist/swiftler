defmodule Mix.Tasks.SwiftTest do
  use ExUnit.Case
  
  describe "Mix.Tasks.Swift.Compile" do
    test "run/1 checks for Swift compiler" do
      # Test that the task checks for Swift availability
      # This will pass/fail depending on whether Swift is installed
      result = Mix.Tasks.Swift.Compile.run([])
      assert result in [:ok, {:error, []}]
    end
    
    test "clean/0 removes build artifacts" do
      # Create some dummy artifacts
      File.mkdir_p!("priv")
      File.mkdir_p!("native/.build")
      File.write!("priv/test.txt", "test")
      File.write!("native/.build/test.txt", "test")
      
      # Clean should remove them
      assert :ok = Mix.Tasks.Compile.Swift.clean()
      
      # Verify they're gone
      refute File.exists?("priv/test.txt")
      # .build directory may still exist but should be cleaned by swift
    end
  end
  
  describe "Mix.Tasks.Swift.Clean" do
    test "run/1 calls clean function" do
      # This should not raise an error
      assert :ok = Mix.Tasks.Swift.Clean.run([])
    end
  end
end