# API Reference

This document provides a complete reference for Swiftler's API.

## Elixir API

### `use Swiftler`

Configures a module to use Swift NIFs.

```elixir
use Swiftler, otp_app: :my_app
```

#### Options

- `:otp_app` (required) - The OTP application containing the Swift code
- `:crate` - The Swift package name (defaults to `"swiftler"`)
- `:load_data` - Additional data to pass to NIF on_load (defaults to `0`)
- `:skip_compilation?` - Skip Swift compilation (defaults to `false`)

#### Example

```elixir
defmodule MyApp.Calculator do
  use Swiftler, 
    otp_app: :my_app,
    crate: "calculator_nifs",
    load_data: %{version: 1}
end
```

### `swift_function/1` Macro

Declares a Swift function signature for NIF binding.

```elixir
swift_function function_name(param: :type, ...) :: :return_type
```

#### Supported Types

- `:int` - 64-bit integer
- `:double` - 64-bit floating point
- `:string` - UTF-8 string
- `:bool` - Boolean value
- `:binary` - Binary data
- `:tuple` - Tuple (for compound types)
- `:list` - List of supported types
- `:map` - Map with string keys

#### Examples

```elixir
# Basic function
swift_function add(a: :int, b: :int) :: :int

# String manipulation
swift_function format(template: :string, values: :list) :: :string

# Complex types
swift_function process(data: :map) :: :tuple

# Optional scheduling
swift_function heavy_compute(input: :binary) :: :binary, schedule: :dirty_cpu
```

### Mix Tasks

#### `mix swift.compile`

Compiles the Swift package and generates the dynamic library.

```bash
mix swift.compile
```

Options:
- `--silent` - Suppress output

#### `mix swift.clean`

Cleans Swift build artifacts.

```bash
mix swift.clean
```

#### `mix swiftler.new`

Generates a new Swift NIF project structure.

```bash
mix swiftler.new [options]
```

Options:
- `--name NAME` - Set the NIF name
- `--module MODULE` - Set the Elixir module name
- `--path PATH` - Set the Swift package path (default: "native")

Example:
```bash
mix swiftler.new --name math_nifs --module MyApp.Math --path swift
```

## Swift API

### `@nif` Attribute

Marks a Swift function for export as a NIF.

```swift
@nif func functionName(_ param: Type) -> ReturnType {
    // implementation
}
```

#### Requirements

- Functions must be top-level (not in a class or struct)
- Parameter names must use underscore (`_`) for external names
- Return types must be NIF-compatible
- Functions must be included in `#nifLibrary`

#### Examples

```swift
@nif func calculate(_ x: Double, _ y: Double) -> Double {
    sqrt(x * x + y * y)
}

@nif func parseJSON(_ json: String) -> [String: Any]? {
    // JSON parsing implementation
}
```

### `#nifLibrary` Macro

Declares the NIF library configuration.

```swift
#nifLibrary(name: "library_name", functions: [
    function1(_:),
    function2(_:_:),
    // ...
])
```

#### Parameters

- `name` - The library name (must match Elixir module expectations)
- `functions` - Array of function references to export

#### Example

```swift
import Swiftler

#nifLibrary(name: "math_utils", functions: [
    add(_:_:),
    subtract(_:_:),
    multiply(_:_:),
    divide(_:_:),
    sqrt(_:),
    power(_:_:)
])

@nif func add(_ a: Int, _ b: Int) -> Int { a + b }
@nif func subtract(_ a: Int, _ b: Int) -> Int { a - b }
// ... more functions
```

### Type Conversions

#### Automatic Conversions

Swiftler automatically handles conversions between Swift and Erlang types:

```swift
// Swift Int <-> Erlang integer
@nif func increment(_ n: Int) -> Int { n + 1 }

// Swift String <-> Erlang binary/string
@nif func uppercase(_ s: String) -> String { s.uppercased() }

// Swift Bool <-> Erlang boolean
@nif func negate(_ b: Bool) -> Bool { !b }

// Swift Double <-> Erlang float
@nif func half(_ x: Double) -> Double { x / 2.0 }
```

#### Collections

```swift
// Arrays
@nif func sum(_ numbers: [Int]) -> Int {
    numbers.reduce(0, +)
}

// Dictionaries
@nif func counts(_ items: [String]) -> [String: Int] {
    items.reduce(into: [:]) { counts, item in
        counts[item, default: 0] += 1
    }
}
```

#### Custom Types

For custom types, use tuples or dictionaries:

```swift
// Return as tuple
@nif func getPoint() -> (Double, Double) {
    (x: 10.0, y: 20.0)
}

// Return as dictionary
@nif func getUser(_ id: Int) -> [String: Any] {
    [
        "id": id,
        "name": "John Doe",
        "active": true
    ]
}
```

## Configuration

### Package.swift Configuration

Example Swift package configuration for Swiftler:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyNIFs",
    products: [
        .library(
            name: "MyNIFs",
            type: .dynamic,
            targets: ["MyNIFs"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/tuist/swiftler", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "MyNIFs",
            dependencies: [
                .product(name: "Swiftler", package: "swiftler")
            ]
        ),
    ]
)
```

### Environment Variables

- `SWIFTLER_SKIP_COMPILATION` - Set to `"true"` to skip Swift compilation
- `SWIFT_BUILD_FLAGS` - Additional flags for Swift build

## Error Handling

### Swift Errors

Swift errors are automatically converted to Elixir error tuples:

```swift
enum MathError: Error {
    case divisionByZero
}

@nif func safeDivide(_ a: Int, _ b: Int) throws -> Int {
    guard b != 0 else {
        throw MathError.divisionByZero
    }
    return a / b
}
```

In Elixir:
```elixir
case MyNIFs.safe_divide(10, 0) do
  {:ok, result} -> result
  {:error, reason} -> # Handle error
end
```

### Fatal Errors

Use `fatalError` for unrecoverable errors:

```swift
@nif func mustSucceed(_ input: String) -> String {
    guard !input.isEmpty else {
        fatalError("Input cannot be empty")
    }
    return process(input)
}
```

## Performance Guidelines

### NIF Execution Time

Keep NIF execution under 1 millisecond:

```swift
@nif func quickOperation(_ n: Int) -> Int {
    // Fast operation
    n * 2
}

// For longer operations, use dirty schedulers
@nif func heavyOperation(_ data: Data) -> Data {
    // Mark as dirty in Elixir:
    // swift_function heavy_operation(data: :binary) :: :binary, 
    //   schedule: :dirty_cpu
}
```

### Memory Usage

Be mindful of memory allocation:

```swift
// Prefer returning existing data
@nif func getConstant() -> String {
    "constant_value"  // No allocation
}

// Over creating new data
@nif func createLargeArray(_ size: Int) -> [Int] {
    Array(repeating: 0, count: size)  // Allocates memory
}
```

## Troubleshooting

For common issues and solutions, see the [Troubleshooting Guide](troubleshooting.md).