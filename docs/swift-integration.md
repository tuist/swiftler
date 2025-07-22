# Swift Integration Guide

This guide covers advanced Swift integration patterns and best practices for Swiftler.

## Swift Package Structure

Swiftler projects follow a standard Swift Package Manager structure:

```
your_project/
├── lib/
│   └── your_module.ex       # Elixir module with Swiftler
├── native/                  # Swift package directory
│   ├── Package.swift        # Swift package manifest
│   └── Sources/
│       └── YourModule/
│           └── YourModule.swift
└── priv/                    # Compiled dynamic libraries
```

## Swift Macros

Swiftler provides two essential macros for NIF integration:

### `@nif` Macro

Marks a Swift function for export as a NIF:

```swift
@nif func add(_ a: Int, _ b: Int) -> Int {
    a + b
}
```

The `@nif` macro:
- Generates C-compatible wrapper functions
- Handles type conversion between Swift and Erlang
- Creates the necessary NIF export declarations

### `#nifLibrary` Macro

Declares the NIF library and its exported functions:

```swift
#nifLibrary(name: "math_nifs", functions: [
    add(_:_:), 
    subtract(_:_:), 
    multiply(_:_:), 
    divide(_:_:)
])
```

## Type Mappings

Swiftler automatically converts between Swift and Elixir types:

| Swift Type | Elixir Type | Notes |
|------------|-------------|-------|
| `Int` | `:int` | 64-bit integer |
| `Double` | `:double` | 64-bit float |
| `String` | `:string` | UTF-8 encoded |
| `Bool` | `:bool` | `true`/`false` |

### Custom Type Example

```swift
// Swift
struct Point {
    let x: Double
    let y: Double
}

@nif func distance(_ p1: Point, _ p2: Point) -> Double {
    let dx = p2.x - p1.x
    let dy = p2.y - p1.y
    return sqrt(dx * dx + dy * dy)
}
```

```elixir
# Elixir
swift_function distance(p1: :tuple, p2: :tuple) :: :double
```

## Memory Management

Swift's automatic reference counting (ARC) works seamlessly with NIFs:

```swift
@nif func processData(_ data: String) -> String {
    // Memory is automatically managed
    let processed = data.uppercased()
    return processed
}
```

### Best Practices

1. **Avoid Long-Running Operations**: NIFs block the scheduler thread
2. **Use Immutable Data**: Prefer value types over reference types
3. **Handle Errors Gracefully**: Use guard statements and proper error handling

## Advanced Patterns

### Working with Collections

```swift
@nif func sum(_ numbers: [Int]) -> Int {
    numbers.reduce(0, +)
}

@nif func frequencies(_ words: [String]) -> [String: Int] {
    words.reduce(into: [:]) { counts, word in
        counts[word, default: 0] += 1
    }
}
```

### Async Operations

For long-running operations, consider using dirty schedulers:

```elixir
defmodule HeavyComputation do
  use Swiftler, otp_app: :my_app
  
  # Mark as dirty NIF
  swift_function compute(data: :binary) :: :binary, 
    schedule: :dirty_cpu
end
```

### Working with Binary Data

```swift
@nif func processImage(_ imageData: Data) -> Data {
    // Process binary data
    var processed = imageData
    // ... image processing logic
    return processed
}
```

## Debugging Swift NIFs

### Enable Debug Symbols

In your `Package.swift`:

```swift
let package = Package(
    name: "MyNIFs",
    products: [
        .library(
            name: "MyNIFs",
            type: .dynamic,
            targets: ["MyNIFs"]
        ),
    ],
    targets: [
        .target(
            name: "MyNIFs",
            swiftSettings: [
                .unsafeFlags(["-g"])  // Debug symbols
            ]
        ),
    ]
)
```

### Logging

Use Swift's logging framework:

```swift
import os

private let logger = Logger(subsystem: "com.example.mynifs", category: "NIF")

@nif func debugFunction(_ input: String) -> String {
    logger.debug("Processing input: \(input)")
    let result = input.uppercased()
    logger.debug("Result: \(result)")
    return result
}
```

## Performance Optimization

### 1. Minimize Allocations

```swift
// Avoid
@nif func inefficient(_ n: Int) -> [Int] {
    var result: [Int] = []
    for i in 0..<n {
        result.append(i * i)  // Multiple allocations
    }
    return result
}

// Prefer
@nif func efficient(_ n: Int) -> [Int] {
    (0..<n).map { $0 * $0 }  // Single allocation
}
```

### 2. Use Value Types

```swift
// Prefer structs over classes for NIF data
struct ComputationResult {
    let value: Double
    let iterations: Int
}

@nif func compute(_ input: Double) -> ComputationResult {
    // ... computation logic
    return ComputationResult(value: result, iterations: count)
}
```

### 3. Batch Operations

```swift
@nif func batchProcess(_ items: [String]) -> [String] {
    // Process all items in one NIF call
    items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
}
```

## Testing Swift NIFs

### Unit Testing in Swift

Create a test target in your `Package.swift`:

```swift
.testTarget(
    name: "MyNIFsTests",
    dependencies: ["MyNIFs"]
)
```

Write Swift tests:

```swift
import XCTest
@testable import MyNIFs

final class MyNIFsTests: XCTestCase {
    func testAdd() {
        XCTAssertEqual(add(2, 3), 5)
    }
}
```

### Integration Testing in Elixir

```elixir
defmodule MyNIFsTest do
  use ExUnit.Case
  
  test "add/2 adds two numbers" do
    assert MyNIFs.add(2, 3) == 5
  end
end
```

## Common Pitfalls

### 1. String Encoding

Always ensure strings are UTF-8 encoded:

```swift
@nif func processText(_ text: String) -> String {
    // Swift strings are always UTF-8
    text.data(using: .utf8)
    // ... process
}
```

### 2. Integer Overflow

Be aware of integer size differences:

```swift
@nif func safePower(_ base: Int, _ exp: Int) -> Int? {
    let (result, overflow) = base.multipliedReportingOverflow(by: exp)
    return overflow ? nil : result
}
```

### 3. Resource Leaks

Clean up resources properly:

```swift
@nif func processFile(_ path: String) -> String? {
    guard let file = FileHandle(forReadingAtPath: path) else {
        return nil
    }
    defer { file.closeFile() }  // Always clean up
    
    // ... process file
}
```

## Next Steps

- Review the [API Reference](api-reference.md) for detailed function documentation
- Check [Troubleshooting](troubleshooting.md) for common issues and solutions