defmodule Mix.Tasks.Swift.Compile do
  @moduledoc """
  Compiles Swift source files.
  """
  
  use Mix.Task
  
  @shortdoc "Compile Swift sources"
  
  def run(args) do
    Mix.Tasks.Compile.Swift.run(args)
  end
end