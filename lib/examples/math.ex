defmodule Examples.Math do
  @moduledoc """
  Example module demonstrating Swift function calls from Elixir.
  This is a documentation example - it doesn't actually load Swift code.
  """

  # This would normally be: use Swiftler, otp_app: :your_app
  # But for this example, we'll define the functions manually
  
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def multiply(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def greet(_name), do: :erlang.nif_error(:nif_not_loaded)
  def calculate_circle_area(_radius), do: :erlang.nif_error(:nif_not_loaded)
  def fibonacci(_n), do: :erlang.nif_error(:nif_not_loaded)
  def is_prime(_number), do: :erlang.nif_error(:nif_not_loaded)

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
