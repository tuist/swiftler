defmodule TestCalculator do
  @on_load :load_nif

  def load_nif do
    path = :code.priv_dir(:calculator) |> to_string() |> Path.join("libCalculatorNative")
    :erlang.load_nif(path, 0)
  end

  def greet(_name), do: :erlang.nif_error(:nif_not_loaded)
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end