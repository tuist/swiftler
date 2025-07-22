# AGENT.md

This file provides guidance to AI coding agents when working with code in this repository.

**Important**: This file should be updated whenever significant changes are made to the project structure, build process, architecture, or development workflows to ensure AI agents have accurate and current information.

## Updating This File

**After every change**, consider if any decisions were made that impact the development context:
- New patterns or conventions adopted
- Testing approaches (e.g., using ExUnit.Case's tmp_dir instead of custom helpers)
- Architecture decisions
- Tool preferences
- API design choices

Update this file immediately when such decisions are made to maintain accurate context for future development.

## Project Overview

Swiftler is a library for calling Swift code from Elixir using NIFs (Native Implemented Functions), similar to how [Rustler](https://github.com/rusterlium/rustler) works for Rust. The API design is influenced by the [swift-nif](https://github.com/yaglo/swift-nif) prototype. The project enables seamless integration between Elixir and Swift through dynamic library compilation and automatic NIF binding generation.

## Key Development Commands

### Building and Testing
- `mix deps.get` - Install Elixir dependencies
- `mix swiftler.new` - Generate new Swift NIF project structure
- `mix swift.compile` - Compile Swift code into dynamic library (copies to priv/)
- `mix compile` - Compile everything including Swift code (if `:swift` is in compilers list)
- `mix test` - Run the full test suite
- `mix format` - Format Elixir code
- `mix format --check-formatted` - Check if code is properly formatted
- `mix swift.clean` - Clean Swift build artifacts

### Swift Package Manager Commands (run in root directory)
- `swift build` - Build Swift package
- `swift test` - Run Swift tests
- `swift package clean` - Clean Swift build artifacts

## Architecture

### Core Components

1. **Elixir Layer** (`lib/`):
   - `Swiftler` module: Main entry point with `__using__` macro
   - `Swiftler.Macros`: Defines `swift_function` and `@swift_function` macros for generating NIF stubs
   - Mix tasks for compilation and cleaning

2. **Swift Layer** (`Sources/`):
   - Uses Swift Package Manager with macro and library targets
   - `CErlang` target: C bridge for Erlang NIF integration (erl_nif.h)
   - `Swiftler`: Main module exporting macros (`@nif`, `#nifLibrary`)
   - `SwiftlerMacros`: Swift macro implementations for code generation
   - `SwiftlerSupport`: Support utilities and type conversions for NIF integration

3. **Integration Flow**:
   - Swift macros generate C-compatible NIF functions at compile time
   - Swift code compiles to dynamic library (`.dylib`/`.so`)
   - Dynamic library copied to `priv/` for NIF loading
   - Elixir loads the dynamic library and calls Swift functions through NIF interface

### Dynamic Library Approach

The project uses a dynamic library compilation model:
- Swift code compiles to `.dylib` (macOS) or `.so` (Linux) files using Swift Package Manager
- Dynamic library is copied to `priv/` during compilation
- Elixir loads the dynamic library at runtime using NIF system

### Macro System

**Swift Side:**
- `@nif` - Marks Swift functions for NIF export, generates C-compatible wrappers
- `#nifLibrary(name: String, functions: [Any])` - Generates NIF library initialization code
- Integrates with Swift's macro system for compile-time code generation
- Supports Int, String, and other basic types with automatic conversion

**Elixir Side:**
- Automatic compilation at compile-time when using `use Swiftler, otp_app: :app_name`
- Standard NIF loading using `:erlang.load_nif` via `@on_load` hook
- Function stubs return `:erlang.nif_error(:nif_not_loaded)` until library is loaded
- Direct function calls to Swift code through NIF interface
- Manifest tracking for automatic recompilation when Swift files change

## Development Environment

### Requirements
- Elixir 1.18.0+ with OTP 27.0+
- Swift 6.0+ (Swift is always required and should be assumed to be present in all environments)
- macOS (primary development platform)

### Project Structure
```
├── lib/                    # Elixir source code
│   ├── swiftler.ex        # Main module
│   └── mix/tasks/         # Mix tasks for Swift compilation
├── Sources/               # Swift package source code
│   ├── Swiftler/          # Main Swiftler module and macros
│   ├── SwiftlerMacros/    # Swift macro implementations
│   ├── SwiftlerSupport/   # Support utilities and type conversions
│   └── CErlang/           # C bridge for Erlang NIF integration
├── Example/               # Example usage
├── Tests/                 # Swift tests
├── test/                  # Elixir tests
├── Package.swift          # Swift package configuration
└── priv/                  # Generated dynamic libraries
```

### CI/CD
- GitHub Actions runs on macOS-latest with separate jobs for formatting, compilation, and tests
- All compilation runs with warnings as errors (Elixir: `--warnings-as-errors`, Swift: `-Xswiftc -warnings-as-errors`)
- Tests formatting, Swift compilation, and Elixir tests in parallel jobs
- Requires both Elixir and Swift environments

### Pre-Push Checklist
Before pushing code or creating pull requests, ensure:
1. **Format all code**: Run `mix format` to format Elixir code
2. **Check formatting**: Run `mix format --check-formatted` to verify formatting
3. **Compile without warnings**: 
   - Elixir: `mix compile --warnings-as-errors`
   - Swift: `swift build -Xswiftc -warnings-as-errors`
4. **Run all tests**: `mix test` and `swift test`
5. **Test examples**: If changes affect the API, test the example projects

## Code Style and Conventions

### Elixir
- Follow standard Elixir formatting (enforced by `mix format`)
- Use descriptive module and function names
- Document public functions with `@doc`
- Prefer pattern matching over conditional logic

### Swift
- Follow Swift API Design Guidelines
- Use `@nif` macro for NIF-exported functions
- Prefix NIF functions with descriptive names
- Handle errors gracefully in NIF boundary functions

## Testing Guidelines

### Elixir Tests
- Place tests in `test/` directory
- Use ExUnit framework
- Test macro generation and compilation workflows
- Verify error handling for invalid Swift function signatures
- Use ExUnit.Case's `@tag :tmp_dir` for tests requiring temporary directories instead of custom helpers
- Prefer built-in ExUnit utilities over custom test helpers when available
- Do not check for Swift availability in tests - assume Swift is always present
- Mix tasks should not print output during tests unless in verbose mode
- Use ExUnit.CaptureIO to suppress output when testing Mix tasks
- Tag slow tests (like Swift builds) with `@tag :slow` to allow excluding them during rapid development
- Separate structure validation from build verification in tests for faster feedback
- Use `swift package dump-package` for package validation instead of actual builds
- Do not test actual Swift builds in automated tests due to long compilation times (5-10+ minutes)
- Manual testing of builds should be done outside the test suite when needed
- When creating examples or demos, use local `--swiftler-path` to avoid slow SwiftSyntax compilation

### Swift Tests
- Run Swift tests with `swift test` in `native/` directory
- Test core Swift functionality independently of NIF integration
- Use Swift Testing framework

### Integration Tests
- Test full Elixir → Swift → NIF pipeline
- Verify static library generation and linking
- Test type conversion between Elixir and Swift

## Security Considerations

### NIF Safety
- All Swift NIF functions must handle invalid input gracefully
- Use proper memory management in C bridge code
- Validate all inputs at the NIF boundary
- Avoid exposing internal Swift errors to Elixir layer

### Build Security
- Static libraries are self-contained with no external dependencies
- Swift Package Manager handles dependency verification
- No dynamic library loading reduces attack surface

## Development Workflows

### Setting Up a New Swift NIF Project
1. Add Swiftler to your Elixir project dependencies
2. Run `mix swiftler.new` to generate project structure
3. Customize the generated Swift functions as needed
4. Run `mix swift.compile` to build dynamic library
5. Test your integration with `mix test`

### Adding New Swift Functions to Existing Project
1. Edit your Swift source file in `native/Sources/`
2. Define Swift function with `@nif` macro for NIF export
3. Include function in `#nifLibrary` declaration
4. Add corresponding Elixir function stub to your module
5. Run `mix swift.compile` to build dynamic library
6. Test with `mix test` to verify integration

### Mix Task Architecture
- `Mix.Tasks.Swiftler.New` generates new Swift NIF project structure
- `Mix.Tasks.Compile.Swift` handles Swift compilation workflow with automatic recompilation support
- `Mix.Tasks.Swift.Compile` and `Mix.Tasks.Swift.Clean` provide user-facing commands
- Compilation copies dynamic library to `priv/` for NIF loading
- Manifest tracking enables incremental compilation based on file changes

## Current Development Status

The project is in active development with working macro system and dynamic library generation. The Swift macros generate C-compatible NIF code, and the compilation process creates loadable dynamic libraries for Elixir NIF integration.

### Recent Improvements
- Automatic recompilation support similar to Rustler
- Manifest tracking to detect source file changes
- Compile-time Swift compilation when using `use Swiftler`
- Integration with Mix compiler pipeline via `:swift` compiler
