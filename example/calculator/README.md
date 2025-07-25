# Calculator Example

This example demonstrates how to use Swiftler to create Swift-powered NIFs for Elixir.

## First Time Setup

The first build will compile SwiftSyntax which can take 5-10 minutes. To avoid this during `mix compile`, you can build the Swift library separately:

```bash
# Build Swift library (only needed once, takes 5-10 minutes)
./build_swift.sh

# Now you can run mix commands without rebuilding Swift
mix test
```

## Regular Development

After the initial build, subsequent compilations will be much faster. The manifest-based compilation system will only rebuild when Swift sources change.

```bash
# Run tests
mix test

# Run interactive shell
iex -S mix
```

## Example Usage

```elixir
iex> Calculator.add(5, 3)
8

iex> Calculator.multiply(4, 7)
28

iex> Calculator.greet("World")
"Hello, World! Welcome to Swiftler Calculator."
```