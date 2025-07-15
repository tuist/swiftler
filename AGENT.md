# AGENT.md

This file provides guidance to AI coding agents when working with code in this repository.

**Important**: This file should be updated whenever significant changes are made to the project structure, build process, architecture, or development workflows to ensure AI agents have accurate and current information.

## Project Overview

Swiftler is a library for calling Swift code from Elixir using NIFs (Native Implemented Functions), similar to how [Rustler](https://github.com/rusterlium/rustler) works for Rust. The API design is influenced by the [swift-nif](https://github.com/yaglo/swift-nif) prototype. The project enables seamless integration between Elixir and Swift through dynamic library compilation and automatic NIF binding generation.

## Key Development Commands

### Building and Testing
- `mix deps.get` - Install Elixir dependencies
- `mix swift.compile` - Compile Swift code into static library (copies to priv/libswiftler.a)
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
- Standard NIF loading using `:erlang.load_nif`
- Function stubs return `:erlang.nif_error(:nif_not_loaded)` until library is loaded
- Direct function calls to Swift code through NIF interface

## Development Environment

### Requirements
- Elixir 1.18.0+ with OTP 27.0+
- Swift 5.9+
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
- GitHub Actions runs on macOS-latest
- Tests formatting, Swift compilation, and Elixir tests
- Requires both Elixir and Swift environments

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

### Adding New Swift Functions
1. Import Swiftler in your Swift module
2. Define Swift function with `@nif` macro for NIF export
3. Include function in `#nifLibrary` declaration
4. Create corresponding Elixir NIF module with function stubs
5. Run `mix swift.compile` to build dynamic library
6. Test with `mix test` to verify integration

### Mix Task Architecture
- `Mix.Tasks.Compile.Swift` handles Swift compilation workflow
- `Mix.Tasks.Swift.Compile` and `Mix.Tasks.Swift.Clean` provide user-facing commands
- Compilation copies dynamic library to `priv/` for NIF loading

## Current Development Status

The project is in active development with working macro system and dynamic library generation. The Swift macros generate C-compatible NIF code, and the compilation process creates loadable dynamic libraries for Elixir NIF integration.