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

> **Note**: Binary data, tuples, lists, and maps are not yet supported but are planned for future releases.

#### Examples

```elixir
# Integer arithmetic
swift_function add(a: :int, b: :int) :: :int

# String manipulation
swift_function uppercase(text: :string) :: :string

# Boolean operations
swift_function is_even(n: :int) :: :bool

# Floating point math
swift_function calculate_area(radius: :double) :: :double
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

@nif func isValidJSON(_ json: String) -> Bool {
    // Check if string is valid JSON
    json.data(using: .utf8).flatMap { data in
        try? JSONSerialization.jsonObject(with: data)
    } != nil
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

#### Working with Limited Types

Since Swiftler currently supports only basic types, you can encode complex data as strings:

```swift
// Encode multiple values as JSON string
@nif func getPoint() -> String {
    let point = ["x": 10.0, "y": 20.0]
    let data = try! JSONSerialization.data(withJSONObject: point)
    return String(data: data, encoding: .utf8)!
}

// Encode lists as comma-separated values
@nif func joinNumbers(_ a: Int, _ b: Int, _ c: Int) -> String {
    "\(a),\(b),\(c)"
}

// Parse on the Elixir side
// point_json = MyNIFs.get_point()
// {:ok, point} = Jason.decode(point_json)
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

Since Swiftler doesn't yet support Swift's error throwing mechanism across the NIF boundary, handle errors by returning encoded error states:

```swift
@nif func safeDivide(_ a: Int, _ b: Int) -> String {
    guard b != 0 else {
        return "error:division_by_zero"
    }
    return "ok:\(a / b)"
}
```

In Elixir:
```elixir
case MyNIFs.safe_divide(10, 0) do
  "ok:" <> result -> String.to_integer(result)
  "error:" <> reason -> {:error, String.to_atom(reason)}
end
```

### Validation

Use guard statements to validate inputs:

```swift
@nif func sqrt(_ n: Double) -> Double {
    guard n >= 0 else {
        return Double.nan  // Return NaN for invalid input
    }
    return n.squareRoot()
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

// Avoid long-running operations in NIFs
// Consider breaking them into smaller chunks
// or using ports/GenServers for heavy computation
```

### Memory Usage

Be mindful of memory allocation:

```swift
// Prefer returning existing data
@nif func getConstant() -> String {
    "constant_value"  // No allocation
}

// Be careful with string concatenation in loops
@nif func buildString(_ count: Int) -> String {
    // This allocates memory for each concatenation
    var result = ""
    for i in 0..<count {
        result += "Item \(i), "
    }
    return result
}
```

## Troubleshooting

For common issues and solutions, see the [Troubleshooting Guide](troubleshooting.md).