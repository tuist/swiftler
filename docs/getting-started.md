# Getting Started with Swiftler

This guide will help you get up and running with Swiftler in your Elixir project.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Elixir** 1.18.0 or later
- **Swift** 6.0 or later
- **macOS** or Linux (macOS is the primary development platform)

You can verify your installations:

```bash
elixir --version
swift --version
```

## Installation

Add Swiftler to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:swiftler, "~> 0.1.0"}
  ]
end
```

Then fetch the dependency:

```bash
mix deps.get
```

## Your First Swift NIF

### 1. Generate the Swift Package Structure

Use the Swiftler generator to create the necessary files:

```bash
mix swiftler.new
```

This creates:
- `native/Package.swift` - Swift package configuration
- `native/Sources/YourApp/YourApp.swift` - Swift source file
- `lib/your_app_swift.ex` - Elixir module for loading the NIF

### 2. Define Your Swift Functions

Edit `native/Sources/YourApp/YourApp.swift`:

```swift
import Swiftler

#nifLibrary(name: "your_app", functions: [add(_:_:), greet(_:)])

@nif func add(_ a: Int, _ b: Int) -> Int {
    a + b
}

@nif func greet(_ name: String) -> String {
    "Hello, \(name)!"
}
```

### 3. Create Your Elixir Module

In your Elixir module, use Swiftler:

```elixir
defmodule YourApp.Math do
  use Swiftler, otp_app: :your_app
  
  swift_function add(a: :int, b: :int) :: :int
  swift_function greet(name: :string) :: :string
end
```

### 4. Compile and Use

That's it! Swiftler automatically compiles your Swift code when you compile your Elixir project:

```elixir
iex> YourApp.Math.add(5, 3)
8

iex> YourApp.Math.greet("World")
"Hello, World!"
```

## What's Next?

- Learn about [Swift Integration](swift-integration.md) patterns
- Explore the [API Reference](api-reference.md)
- Check out [Troubleshooting](troubleshooting.md) if you encounter issues

## Key Features

### Automatic Compilation

Swiftler compiles your Swift code automatically during module compilation - no need to modify your Mix project configuration:

```elixir
# No compilers list modification needed!
def project do
  [
    app: :my_app,
    deps: deps()
  ]
end
```

### Hot Reloading

Changes to Swift source files are automatically detected and trigger recompilation thanks to `@external_resource` tracking.

### Type Safety

Swiftler validates types at compile time:

```elixir
swift_function add(a: :int, b: :int) :: :int  # ✅ Valid
swift_function add(a: :atom, b: :int) :: :int # ❌ Compile error
```

## Common Patterns

### Working with Different Types

```swift
// Numbers
@nif func multiply(_ x: Double, _ y: Double) -> Double {
    x * y
}

// Strings
@nif func reverse(_ s: String) -> String {
    String(s.reversed())
}

// Booleans
@nif func isEven(_ n: Int) -> Bool {
    n % 2 == 0
}
```

### Error Handling

Swift errors are automatically converted to Elixir error tuples:

```swift
@nif func divide(_ a: Int, _ b: Int) -> Int {
    guard b != 0 else { 
        fatalError("Division by zero")
    }
    return a / b
}
```

## Performance Considerations

Swift NIFs run in the same OS thread as the Erlang scheduler, so:

- Keep NIF functions fast (< 1ms)
- For longer operations, consider using dirty NIFs
- Be mindful of memory allocation

## Next Steps

Ready to dive deeper? Check out our [Swift Integration Guide](swift-integration.md) for advanced patterns and best practices.