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

Swiftler currently supports basic types with automatic conversion:

| Swift Type | Elixir Type | Notes |
|------------|-------------|-------|
| `Int` | `:int` | 64-bit integer |
| `Double` | `:double` | 64-bit float |
| `String` | `:string` | UTF-8 encoded |
| `Bool` | `:bool` | `true`/`false` |

> **Note**: Arrays, dictionaries, and custom types are not yet supported but are planned for future releases.

### Working with Supported Types

```swift
// Swift
@nif func calculate(_ price: Double, _ taxRate: Double) -> Double {
    price * (1 + taxRate)
}

@nif func isValidEmail(_ email: String) -> Bool {
    email.contains("@") && email.contains(".")
}

@nif func concatenate(_ a: String, _ b: String) -> String {
    a + " " + b
}
```

```elixir
# Elixir
swift_function calculate(price: :double, tax_rate: :double) :: :double
swift_function is_valid_email(email: :string) :: :bool
swift_function concatenate(a: :string, b: :string) :: :string
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

### String Processing

Since Swiftler currently supports basic types, you can create powerful string processing functions:

```swift
@nif func sanitize(_ input: String) -> String {
    input
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
}

@nif func extractDomain(_ url: String) -> String {
    guard let url = URL(string: url),
          let host = url.host else {
        return ""
    }
    return host
}
```

### Mathematical Operations

```swift
@nif func fibonacci(_ n: Int) -> Int {
    guard n > 1 else { return n }
    var a = 0, b = 1
    for _ in 2...n {
        (a, b) = (b, a + b)
    }
    return b
}

@nif func isPrime(_ n: Int) -> Bool {
    guard n > 1 else { return false }
    guard n > 3 else { return true }
    guard n % 2 != 0 && n % 3 != 0 else { return false }
    
    var i = 5
    while i * i <= n {
        if n % i == 0 || n % (i + 2) == 0 {
            return false
        }
        i += 6
    }
    return true
}
```

### Working with Multiple Return Values

While tuples aren't directly supported, you can encode multiple values:

```swift
@nif func divmod(_ a: Int, _ b: Int) -> String {
    guard b != 0 else { return "error:division_by_zero" }
    let quotient = a / b
    let remainder = a % b
    return "\(quotient),\(remainder)"
}
```

```elixir
# In Elixir, parse the result
def divmod(a, b) do
  case YourModule.divmod(a, b) do
    "error:" <> reason -> {:error, String.to_atom(reason)}
    result ->
      [q, r] = String.split(result, ",") |> Enum.map(&String.to_integer/1)
      {q, r}
  end
end
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

### 1. Keep Functions Fast

NIFs run on scheduler threads, so keep execution time under 1ms:

```swift
// Good: Fast computation
@nif func fastHash(_ input: String) -> Int {
    input.hash
}

// Avoid: Long-running computation
@nif func slowComputation(_ n: Int) -> Int {
    // If this takes > 1ms, consider breaking it up
    // or using ports/GenServer instead
}
```

### 2. Efficient String Operations

```swift
@nif func optimizedTrim(_ input: String) -> String {
    // Use Swift's efficient string APIs
    input.trimmingCharacters(in: .whitespacesAndNewlines)
}

@nif func fastValidate(_ email: String) -> Bool {
    // Quick validation without regex compilation
    let parts = email.split(separator: "@")
    return parts.count == 2 && parts[1].contains(".")
}
```

### 3. Precompute When Possible

```swift
// Precompute constants outside the NIF function
private let emailRegex = try! NSRegularExpression(
    pattern: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#,
    options: [.caseInsensitive]
)

@nif func validateEmailRegex(_ email: String) -> Bool {
    let range = NSRange(location: 0, length: email.utf16.count)
    return emailRegex.firstMatch(in: email, options: [], range: range) != nil
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

### 1. NIF Execution Time

Remember that NIFs block the scheduler:

```swift
// Bad: This could block the VM
@nif func slowOperation(_ input: String) -> String {
    Thread.sleep(forTimeInterval: 0.1)  // Never do this!
    return input
}

// Good: Keep it fast
@nif func fastOperation(_ input: String) -> String {
    input.uppercased()  // Microseconds
}
```

### 2. Error Handling

Since exceptions can't cross the NIF boundary, handle errors gracefully:

```swift
// Bad: This will crash the VM
@nif func divide(_ a: Int, _ b: Int) -> Int {
    a / b  // Crashes on division by zero
}

// Good: Safe error handling
@nif func safeDivide(_ a: Int, _ b: Int) -> String {
    guard b != 0 else { return "error:division_by_zero" }
    return String(a / b)
}
```

### 3. Integer Overflow

Be aware of integer limits:

```swift
@nif func factorial(_ n: Int) -> String {
    guard n >= 0 else { return "error:negative_input" }
    guard n <= 20 else { return "error:too_large" }  // 21! overflows Int64
    
    var result = 1
    for i in 1...n {
        result *= i
    }
    return String(result)
}
```

## Next Steps

- Review the [API Reference](api-reference.md) for detailed function documentation
- Check [Troubleshooting](troubleshooting.md) for common issues and solutions