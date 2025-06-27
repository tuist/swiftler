defmodule Examples.Math do
  @moduledoc """
  Example module demonstrating Swift function calls from Elixir.
  """
  
  use Swiftler
  
  # Define Swift functions that will be available in this module
  swift_function add(a: :int, b: :int) :: :int
  swift_function multiply(a: :int, b: :int) :: :int
  swift_function greet(name: :string) :: :string
  swift_function calculate_circle_area(radius: :double) :: :double
  swift_function fibonacci(n: :int) :: :int
  swift_function is_prime(number: :int) :: :bool
  
  @doc """
  Calculate the sum of two numbers using Swift.
  """
  def swift_add(a, b) do
    add(a, b)
  end
  
  @doc """
  Generate Fibonacci sequence up to n using Swift.
  """
  def fibonacci_sequence(n) when n > 0 do
    1..n
    |> Enum.map(&fibonacci/1)
  end
  
  @doc """
  Find all prime numbers up to n using Swift.
  """
  def primes_up_to(n) when n > 1 do
    2..n
    |> Enum.filter(&is_prime/1)
  end
  
  @doc """
  Greet someone using Swift.
  """
  def swift_greet(name) when is_binary(name) do
    greet(name)
  end
  
  @doc """
  Calculate circle area using Swift.
  """
  def circle_area(radius) when is_number(radius) do
    calculate_circle_area(radius * 1.0)
  end
end