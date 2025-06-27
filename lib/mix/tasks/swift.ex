defmodule Mix.Tasks.Swift do
  @moduledoc """
  Provides Swift-related Mix tasks.
  """
  
  use Mix.Task
  
  @shortdoc "Prints Swift-related help"
  def run(_args) do
    Mix.shell().info """
    Available Swift tasks:
    
    mix swift.compile  - Compile Swift sources
    mix swift.clean    - Clean Swift build artifacts
    """
  end
end