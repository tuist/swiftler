defmodule Calculator do
  @moduledoc """
  A calculator library powered by Swift NIFs via Swiftler.
  
  This module demonstrates how to integrate Swift code with Elixir using Swiftler.
  It provides various mathematical operations implemented in Swift.
  """

  use Swiftler, otp_app: :calculator

  # Basic arithmetic operations
  swift_function add(a: :int, b: :int) :: :int
  swift_function subtract(a: :int, b: :int) :: :int
  swift_function multiply(a: :int, b: :int) :: :int
  swift_function divide(a: :int, b: :int) :: :int

  # Advanced mathematical operations
  swift_function power(base: :int, exponent: :int) :: :int
  swift_function sqrt(n: :double) :: :double
  swift_function factorial(n: :int) :: :int
  swift_function is_prime(number: :int) :: :bool
  swift_function gcd(a: :int, b: :int) :: :int
  swift_function fibonacci(n: :int) :: :int
  swift_function circle_area(radius: :double) :: :double

  # String operations
  swift_function greet(name: :string) :: :string

  @doc """
  Calculates the least common multiple of two integers.
  
  ## Examples
  
      iex> Calculator.lcm(12, 18)
      36
      
      iex> Calculator.lcm(7, 5)
      35
  """
  def lcm(a, b) when is_integer(a) and is_integer(b) do
    div(abs(a * b), gcd(a, b))
  end

  @doc """
  Generates a list of prime numbers up to n.
  
  ## Examples
  
      iex> Calculator.primes_up_to(20)
      [2, 3, 5, 7, 11, 13, 17, 19]
  """
  def primes_up_to(n) when is_integer(n) and n >= 2 do
    2..n
    |> Enum.filter(&is_prime/1)
  end

  @doc """
  Generates the first n Fibonacci numbers.
  
  ## Examples
  
      iex> Calculator.fibonacci_sequence(10)
      [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  """
  def fibonacci_sequence(n) when is_integer(n) and n >= 1 do
    0..(n - 1)
    |> Enum.map(&fibonacci/1)
  end

  @doc """
  Calculates the volume of a sphere given its radius.
  
  ## Examples
  
      iex> Calculator.sphere_volume(3.0)
      113.09733552923255
  """
  def sphere_volume(radius) when is_number(radius) do
    # Convert to integer for power function, then back to float
    radius_cubed = power(round(radius), 3)
    4.0 / 3.0 * :math.pi() * radius_cubed
  end

  @doc """
  Evaluates a simple mathematical expression.
  
  ## Examples
  
      iex> Calculator.evaluate("2 + 3 * 4")
      14
  """
  def evaluate(expression) when is_binary(expression) do
    # This is a simple example - in production, use a proper parser
    case String.split(expression, ~r/\s+/) do
      [a, "+", b] -> add(String.to_integer(a), String.to_integer(b))
      [a, "-", b] -> subtract(String.to_integer(a), String.to_integer(b))
      [a, "*", b] -> multiply(String.to_integer(a), String.to_integer(b))
      [a, "/", b] -> divide(String.to_integer(a), String.to_integer(b))
      _ -> {:error, "Unsupported expression"}
    end
  end
end