# Swiftler

A utility for calling Swift code from Elixir, similar to how Rustler works for Rust. Swiftler provides seamless integration between Elixir and Swift through dynamic binary generation and automatic NIF binding generation.

## Features

- 🚀 **Dynamic Binary Integration**: Swift code is compiled into dynamic binaries and integrated through Elixir's NIF system
- 🔧 **Swift Package Manager**: Uses SPM as the build system, following Swift ecosystem conventions
- 📦 **Mix Tasks**: Provides `mix swift.compile` and `mix swift.clean` tasks similar to Rustler
- 🎯 **Automatic Bindings**: Swift macros for automatic NIF binding generation
- 🧪 **Testing Support**: Includes Swift Testing framework integration
- 💼 **Minimal Dependencies**: Lightweight approach with minimal C-related dependencies
- ♻️ **Automatic Recompilation**: Tracks source file changes and only recompiles when necessary

## Installation

Add `swiftler` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:swiftler, "~> 0.1.0"}
  ]
end
```

To enable automatic recompilation when Swift source files change, add `:swift` to your project's compilers list:

```elixir
def project do
  [
    app: :my_app,
    compilers: [:swift] ++ Mix.compilers(),
    # ...
  ]
end
```

## Usage

### 1. Add Swiftler to Your Elixir Project

Add Swiftler to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:swiftler, "~> 0.1.0"}
  ]
end
```

### 2. Generate Swift NIF Project

Use the Swiftler mix task to set up your Swift NIF:

```bash
mix swiftler.new
```

This will create:
- `native/Package.swift` - Swift package configuration
- `native/Sources/YourProject/YourProject.swift` - Swift source with example functions
- `lib/your_project.ex` - Elixir module to load the NIF

You can customize the setup with options:

```bash
# Custom NIF name and module
mix swiftler.new --name calculator --module MyApp.Calculator

# Custom path
mix swiftler.new --path swift_nif
```

### 3. Customize Your Swift Functions

Edit the generated Swift file to add your custom logic:

```swift
import Swiftler

#nifLibrary(name: "calculator", functions: [add(_:_:), multiply(_:_:)])

@nif func add(_ a: Int, _ b: Int) -> Int {
    a + b
}

@nif func multiply(_ a: Int, _ b: Int) -> Int {
    a * b
}
```

### 4. Compile Swift Code

Run the Mix task to compile your Swift code:

```bash
mix swift.compile
```

### 5. Use Your Swift Functions

The generated Elixir module is ready to use:

```elixir
# The module was created by mix swiftler.new
defmodule YourProject do
  use Swiftler, otp_app: :your_app
  
  # Define Swift function signatures
  swift_function add(a: :int, b: :int) :: :int
  swift_function multiply(a: :int, b: :int) :: :int

  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def multiply(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end
```


### 6. Test Your Integration

```elixir
YourProject.add(5, 3)
# => 8

YourProject.multiply(4, 7)
# => 28
```

## Mix Tasks

- `mix swift.compile` - Compiles the Swift package and generates static libraries
- `mix swift.clean` - Cleans Swift build artifacts

## Architecture

Swiftler follows a macro-driven approach:

1. Swift macros (`@nif` and `#nifLibrary`) generate C-compatible NIF code at compile time
2. Swift code is compiled into a dynamic library using Swift Package Manager
3. The dynamic library contains C-compatible functions that can be loaded as NIFs
4. Elixir loads the dynamic library and calls Swift functions through the NIF interface

## Development Status

Swiftler is currently in development. The macro system generates C-compatible NIF code from Swift functions, and dynamic library generation is working. The project now supports the swift-nif API pattern with `@nif` function decorators and `#nifLibrary` declarations.

## Testing

Run the test suite:

```bash
mix test
```

The tests verify that:
- Swift compilation works correctly
- Dynamic binaries are generated
- Elixir macros create proper function stubs
- Type validation works as expected
- NIF integration functions properly

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
- API design influenced by [swift-nif](https://github.com/yaglo/swift-nif) prototype
- Built on top of Swift Package Manager and Elixir's NIF system