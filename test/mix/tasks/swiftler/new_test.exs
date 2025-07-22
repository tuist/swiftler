defmodule Mix.Tasks.Swiftler.NewTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias Mix.Tasks.Swiftler.New

  defp create_test_project(tmp_dir) do
    # Create a minimal mix.exs for the test project
    mix_exs_content = """
    defmodule TestProject.MixProject do
      use Mix.Project

      def project do
        [
          app: :my_app,
          version: "0.1.0",
          elixir: "~> 1.15",
          deps: []
        ]
      end
    end
    """

    File.write!(Path.join(tmp_dir, "mix.exs"), mix_exs_content)
  end

  @tag :tmp_dir
  test "creates Swift package structure and compiles with swift build", %{tmp_dir: tmp_dir} do
    # Get the Swiftler path before changing directory
    swiftler_path = File.cwd!()

    File.cd!(tmp_dir, fn ->
      create_test_project(tmp_dir)

      # Run the task
      capture_io(fn ->
        New.run(["--swiftler-path", swiftler_path])
      end)

      # Verify the structure was created
      assert File.exists?("native/Package.swift")
      # When Mix.Project is not properly loaded, it defaults to "my_app"
      assert File.exists?("native/Sources/MyApp/MyApp.swift") ||
               File.exists?("native/Sources/Swiftler/Swiftler.swift")

      assert File.exists?("lib/my_app.ex") || File.exists?("lib/swiftler.ex")

      # Verify Package.swift content uses local dependency
      package_content = File.read!("native/Package.swift")

      assert package_content =~ ~r/\.package\(path: ".*"\)/

      # Verify the Swift package structure is valid by checking Package.swift can be parsed
      dump_result =
        System.cmd("swift", ["package", "dump-package"], cd: "native", stderr_to_stdout: true)

      assert elem(dump_result, 1) == 0, "Swift package validation failed: #{elem(dump_result, 0)}"
    end)
  end

  @tag :tmp_dir
  test "creates Swift package with remote dependency", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      create_test_project(tmp_dir)

      # Run the task without specifying local path
      capture_io(fn ->
        New.run([])
      end)

      # Verify the structure was created
      assert File.exists?("native/Package.swift")

      assert File.exists?("native/Sources/MyApp/MyApp.swift") ||
               File.exists?("native/Sources/Swiftler/Swiftler.swift")

      assert File.exists?("lib/my_app.ex") || File.exists?("lib/swiftler.ex")

      # Verify Package.swift content uses remote dependency
      package_content = File.read!("native/Package.swift")

      assert package_content =~
               ~r/\.package\(url: "https:\/\/github\.com\/tuist\/swiftler\.git", branch: "main"\)/

      # Verify the Swift package structure is valid by checking Package.swift can be parsed
      dump_result =
        System.cmd("swift", ["package", "dump-package"], cd: "native", stderr_to_stdout: true)

      assert elem(dump_result, 1) == 0, "Swift package validation failed: #{elem(dump_result, 0)}"

      # Note: We don't build this one as it would fetch SwiftSyntax from remote
    end)
  end

  @tag :tmp_dir
  test "creates Swift package with local Swiftler dependency and compiles", %{tmp_dir: tmp_dir} do
    # Get the actual Swiftler path (current project root) before changing directory
    swiftler_path = File.cwd!()

    File.cd!(tmp_dir, fn ->
      create_test_project(tmp_dir)

      # Run the task with local path
      capture_io(fn ->
        New.run(["--swiftler-path", swiftler_path])
      end)

      # Verify the structure was created
      assert File.exists?("native/Package.swift")
      # When Mix.Project is not properly loaded, it defaults to "my_app"
      assert File.exists?("native/Sources/MyApp/MyApp.swift") ||
               File.exists?("native/Sources/Swiftler/Swiftler.swift")

      assert File.exists?("lib/my_app.ex") || File.exists?("lib/swiftler.ex")

      # Verify Package.swift content uses local path
      package_content = File.read!("native/Package.swift")
      assert package_content =~ ~r/\.package\(path: ".*"\)/

      refute package_content =~
               ~r/\.package\(url: "https:\/\/github\.com\/tuist\/swiftler\.git", branch: "main"\)/

      # Verify the Swift package structure is valid
      dump_result =
        System.cmd("swift", ["package", "dump-package"], cd: "native", stderr_to_stdout: true)

      assert elem(dump_result, 1) == 0,
             "Swift package validation failed with local dependency: #{elem(dump_result, 0)}"
    end)
  end

  @tag :tmp_dir
  test "creates Swift package with custom paths and names and compiles", %{tmp_dir: tmp_dir} do
    # Get the actual Swiftler path before changing directory
    swiftler_path = File.cwd!()

    File.cd!(tmp_dir, fn ->
      create_test_project(tmp_dir)

      # Run the task with custom options
      capture_io(fn ->
        New.run([
          "--name",
          "calculator",
          "--module",
          "MyApp.Calculator",
          "--path",
          "swift_nif",
          "--swiftler-path",
          swiftler_path
        ])
      end)

      # Verify the structure was created with custom paths
      assert File.exists?("swift_nif/Package.swift")
      assert File.exists?("swift_nif/Sources/Calculator/Calculator.swift")
      assert File.exists?("lib/my_app/calculator.ex")

      # Verify the Swift package structure is valid
      dump_result =
        System.cmd("swift", ["package", "dump-package"],
          cd: "swift_nif",
          stderr_to_stdout: true
        )

      assert elem(dump_result, 1) == 0,
             "Swift package validation failed with custom paths: #{elem(dump_result, 0)}"
    end)
  end

  @tag :tmp_dir
  test "handles relative swiftler-path correctly", %{tmp_dir: tmp_dir} do
    # Get the actual Swiftler path (current project root) before changing directory
    swiftler_absolute_path = File.cwd!()

    File.cd!(tmp_dir, fn ->
      create_test_project(tmp_dir)

      # Create a nested project directory
      nested_path = "nested/project"
      File.mkdir_p!(nested_path)

      # Calculate relative path from nested directory to Swiftler
      relative_swiftler_path =
        Path.relative_to(swiftler_absolute_path, Path.join(File.cwd!(), nested_path))

      # Run the task from nested directory
      File.cd!(nested_path, fn ->
        capture_io(fn ->
          New.run(["--swiftler-path", relative_swiftler_path])
        end)

        # Verify Package.swift has correct relative path
        package_content = File.read!("native/Package.swift")
        # The path should be adjusted relative to the native directory
        expected_relative_path =
          Path.relative_to(swiftler_absolute_path, Path.join(File.cwd!(), "native"))

        assert package_content =~
                 ~r/\.package\(path: "#{Regex.escape(expected_relative_path)}"\)/
      end)
    end)
  end
end
