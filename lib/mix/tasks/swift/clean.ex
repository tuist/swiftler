defmodule Mix.Tasks.Swift.Clean do
  @moduledoc """
  Cleans Swift build artifacts.
  """

  use Mix.Task

  @shortdoc "Clean Swift build artifacts"

  def run(_args) do
    Mix.Tasks.Compile.Swift.clean()
    # Don't print unless explicitly in verbose mode
    if "--verbose" in System.argv() do
      Mix.shell().info("Cleaned Swift build artifacts")
    end
    :ok
  end
end
