# Swiftler

A utility for calling Swift code from Elixir, similar to how Rustler works for Rust. Swiftler provides seamless integration between Elixir and Swift through static linking and automatic NIF binding generation.

## Features

- 🚀 **Static Library Integration**: Everything is statically compiled for optimal performance and deployment simplicity
- 🔧 **Swift Package Manager**: Uses SPM as the build system, following Swift ecosystem conventions
- 📦 **Mix Tasks**: Provides `mix swift.compile` and `mix swift.clean` tasks similar to Rustler
- 🎯 **Automatic Bindings**: Swift macros for automatic NIF binding generation
- 🧪 **Testing Support**: Includes Swift Testing framework integration
- 💼 **Minimal Dependencies**: Lightweight approach with minimal C-related dependencies

## Installation

Add `swiftler` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:swiftler, "~> 0.1.0"}
  ]
end
```

## Usage

### 1. Create a Swift Package

Create a `native/` directory in your project root and initialize a Swift package:

```bash
mkdir native
cd native
swift package init --type library --name YourProjectNative
```

### 2. Configure Swift Package

Update your `native/Package.swift` to create a static library:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourProjectNative",
    products: [
        .library(
            name: "YourProjectNative",
            type: .static,
            targets: ["YourProjectNative"]
        )
    ],
    targets: [
        .target(
            name: "YourProjectNative"
        )
    ]
)
```

### 3. Write Swift Functions

Create Swift functions in `native/Sources/YourProjectNative/`:

```swift
import Darwin

public func add(_ a: Int32, _ b: Int32) -> Int32 {
    return a + b
}

public func fibonacci_sequence(_ count: Int32) -> [Int32] {
    guard count > 0 else { return [] }
    var sequence: [Int32] = [0, 1]
    for i in 2..<Int(count) {
        sequence.append(sequence[i-1] + sequence[i-2])
    }
    return Array(sequence.prefix(Int(count)))
}
```

### 4. Create Elixir Module

Define your Elixir module using Swiftler macros:

```elixir
defmodule YourProject.Math do
  use Swiftler

  @swift_function add(a: :i32, b: :i32) :: :i32
  @swift_function fibonacci_sequence(count: :i32) :: [:i32]
end
```

### 5. Compile Swift Code

Run the Mix task to compile your Swift code:

```bash
mix swift.compile
```

### 6. Use in Your Application

```elixir
# This will return a placeholder until static linking is fully implemented
YourProject.Math.add(5, 3)
# => {:error, :static_linking_required, "add_swift", [:a, :b]}

YourProject.Math.fibonacci_sequence(10)
# => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

## Mix Tasks

- `mix swift.compile` - Compiles the Swift package and generates static libraries
- `mix swift.clean` - Cleans Swift build artifacts

## Architecture

Swiftler follows a static library approach:

1. Swift code is compiled into a static library using Swift Package Manager
2. The static library is copied to the `priv/` directory
3. Elixir macros generate NIF stubs that will eventually link to the static library
4. At runtime, functions call into the statically linked Swift code

## Development Status

Swiftler is currently in development. The macro system and static library generation are working, but the final NIF linking step is still being implemented. Functions currently return placeholder values indicating static linking is required.

## Testing

Run the test suite:

```bash
mix test
```

The tests verify that:
- Swift compilation works correctly
- Static libraries are generated
- Elixir macros create proper function stubs
- Type validation works as expected

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`mix test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [Rustler](https://github.com/rusterlium/rustler) for Rust-Elixir integration
- Built on top of Swift Package Manager and Elixir's NIF system