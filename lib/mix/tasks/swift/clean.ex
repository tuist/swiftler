defmodule Mix.Tasks.Swift.Clean do
  @moduledoc """
  Cleans Swift build artifacts.
  """
  
  use Mix.Task
  
  @shortdoc "Clean Swift build artifacts"
  
  def run(_args) do
    Mix.Tasks.Compile.Swift.clean()
    Mix.shell().info("Cleaned Swift build artifacts")
  end
end