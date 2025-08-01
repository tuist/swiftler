defmodule Calculator do
  @on_load :load_nif

  def load_nif do
    path = Path.join([__DIR__, "priv", "libCalculatorNative"])
    :erlang.load_nif(String.to_charlist(path), 0)
  end

  # Define the NIF functions
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def subtract(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def multiply(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def divide(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def power(_base, _exp), do: :erlang.nif_error(:nif_not_loaded)
  def sqrt(_n), do: :erlang.nif_error(:nif_not_loaded)
  def factorial(_n), do: :erlang.nif_error(:nif_not_loaded)
  def is_prime(_n), do: :erlang.nif_error(:nif_not_loaded)
  def gcd(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def fibonacci(_n), do: :erlang.nif_error(:nif_not_loaded)
  def circle_area(_radius), do: :erlang.nif_error(:nif_not_loaded)
  def greet(_name), do: :erlang.nif_error(:nif_not_loaded)
  def simple_string_test(), do: :erlang.nif_error(:nif_not_loaded)
end

# Test the module
IO.puts("Loading NIF module...")
Code.ensure_loaded(Calculator)

IO.puts("\nTesting integer functions:")
IO.puts("add(2, 3) = #{Calculator.add(2, 3)}")
IO.puts("multiply(4, 5) = #{Calculator.multiply(4, 5)}")
IO.puts("is_prime(7) = #{Calculator.is_prime(7)}")

IO.puts("\nTesting parameterless string function:")
try do
  result = Calculator.simple_string_test()
  IO.puts("simple_string_test() = #{result}")
rescue
  e -> IO.puts("simple_string_test() error: #{inspect(e)}")
end

IO.puts("\nTesting string function with parameter:")
try do
  result = Calculator.greet("World")
  IO.puts("greet(\"World\") = #{result}")
rescue  
  e -> IO.puts("greet() error: #{inspect(e)}")
end