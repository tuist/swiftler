# Calculator Example

This example demonstrates how to use Swiftler to create Swift-powered NIFs for Elixir.

## Known Issues

1. **Long compilation times**: The first build compiles SwiftSyntax which takes 5-10 minutes.
2. **Symbol not found errors**: If you get `_nif_init: symbol not found` errors, the Swift macro cache may be outdated. Clean rebuild with: `rm -rf native/.build native/.swiftpm`

## First Time Setup

To avoid long compilation during `mix compile`, build the Swift library separately:

```bash
# Clean any cached builds
rm -rf native/.build native/.swiftpm _build priv

# Build Swift library (takes 5-10 minutes on first build)
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