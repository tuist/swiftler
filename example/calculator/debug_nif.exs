defmodule DebugNIF do
  @on_load :load_nif

  def load_nif do
    path = Path.join([__DIR__, "native/.build/release/libCalculatorNative"])
    
    IO.puts "Loading NIF from: #{path}"
    
    case :erlang.load_nif(String.to_charlist(path), 0) do
      :ok -> 
        IO.puts "NIF loaded successfully"
        :ok
      {:error, reason} ->
        IO.puts "Failed to load NIF: #{inspect(reason)}"
        :ok
    end
  end
  
  # Define the greet function stub
  def greet(_name) do
    :erlang.nif_error(:nif_not_loaded)
  end
end

# Test
IO.puts "Testing direct NIF load..."
DebugNIF.load_nif()

try do
  result = DebugNIF.greet("Test")
  IO.puts "Success: #{inspect result}"
rescue
  e ->
    IO.puts "Error: #{inspect e}"
    IO.puts Exception.format(:error, e, __STACKTRACE__)
end