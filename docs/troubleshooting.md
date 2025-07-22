# Troubleshooting Guide

This guide helps you resolve common issues when using Swiftler.

## Compilation Issues

### Swift Build Timeout

**Error:**
```
Failed to compile Swift code for package swiftler: Swift build timed out (30s). 
This usually happens when compiling SwiftSyntax for the first time. 
Please run 'mix swift.compile' manually.
```

**Solution:**
SwiftSyntax compilation can take 5-10 minutes on first build. Run manually:

```bash
mix swift.compile
```

Or increase the timeout in your project by setting the environment variable:
```bash
export SWIFTLER_BUILD_TIMEOUT=600000  # 10 minutes
```

### Swift Compiler Not Found

**Error:**
```
Swift compiler not found. Please install Swift.
```

**Solution:**
1. Install Swift from [swift.org](https://swift.org/download/)
2. Verify installation:
   ```bash
   swift --version
   ```
3. Ensure Swift is in your PATH

### Package.swift Not Found

**Error:**
```
Package.swift not found. Please create a Swift package or use Swiftler in a subdirectory.
```

**Solution:**
Run the generator to create the Swift package structure:
```bash
mix swiftler.new
```

Or manually create `native/Package.swift`.

## Runtime Issues

### NIF Library Not Found

**Error:**
```
Failed to load Swift NIF from /path/to/priv/libswiftler: 
{:load_failed, "Failed to load NIF library..."}
```

**Solutions:**

1. **Compile the Swift code:**
   ```bash
   mix swift.compile
   ```

2. **Check library location:**
   ```bash
   ls priv/
   # Should show libswiftler.dylib (macOS) or libswiftler.so (Linux)
   ```

3. **Clean and rebuild:**
   ```bash
   mix swift.clean
   mix swift.compile
   ```

### Symbol Not Found

**Error:**
```
Failed to find library init function: 'dlsym(0x39624cb20, _nif_init): symbol not found'
```

**Solutions:**

1. **Ensure functions are exported in `#nifLibrary`:**
   ```swift
   #nifLibrary(name: "my_nifs", functions: [
       myFunction(_:)  // Must be listed here
   ])
   ```

2. **Check function signatures match:**
   ```elixir
   # Elixir
   swift_function my_function(input: :string) :: :string
   ```
   ```swift
   // Swift
   @nif func myFunction(_ input: String) -> String { ... }
   ```

### Module Not Loaded

**Error:**
```
error: module Calculator is not loaded and could not be found
```

**Solution:**
The NIF library failed to load during module compilation. Check previous error messages for the root cause.

## Type Errors

### Invalid Type Specification

**Error:**
```
** (ArgumentError) Invalid type: :invalid_type. 
Supported types are: [:int, :double, :string, :bool, :binary, :tuple, :list, :map]
```

**Solution:**
Use only supported types in `swift_function` declarations:
```elixir
# Valid
swift_function process(data: :string) :: :int

# Invalid
swift_function process(data: :atom) :: :float
```

### Type Mismatch

**Error:**
```
** (ArgumentError) argument error
```

**Solution:**
Ensure Elixir arguments match Swift parameter types:
```elixir
# If Swift expects Int
MyNIFs.add(1, 2)      # ✅ Correct
MyNIFs.add(1.0, 2.0)  # ❌ Wrong - passing floats
```

## Platform-Specific Issues

### macOS: Wrong Library Extension

**Issue:** Erlang looks for `.so` files but macOS uses `.dylib`

**Solution:**
Create a symlink:
```bash
cd priv
ln -s libswiftler.dylib libswiftler.so
```

### Linux: Missing Swift Runtime

**Error:**
```
error while loading shared libraries: libswiftCore.so
```

**Solution:**
Install Swift runtime libraries:
```bash
# Ubuntu/Debian
sudo apt-get install libswift5

# Or set library path
export LD_LIBRARY_PATH=/usr/lib/swift/linux:$LD_LIBRARY_PATH
```

## Performance Issues

### Slow NIF Execution

**Symptoms:**
- Application becomes unresponsive
- Scheduler warnings in logs

**Solutions:**

1. **Profile your Swift code:**
   ```swift
   @nif func slowFunction(_ input: String) -> String {
       let start = Date()
       defer {
           print("Execution time: \(Date().timeIntervalSince(start))s")
       }
       // ... implementation
   }
   ```

2. **Use dirty schedulers for long operations:**
   ```elixir
   swift_function heavy_compute(data: :binary) :: :binary, 
     schedule: :dirty_cpu
   ```

3. **Batch operations:**
   ```swift
   // Instead of calling multiple times
   @nif func processBatch(_ items: [String]) -> [String] {
       items.map { processOne($0) }
   }
   ```

### Memory Leaks

**Symptoms:**
- Growing memory usage
- OOM errors

**Solutions:**

1. **Use value types over reference types:**
   ```swift
   // Prefer
   struct Result {
       let value: Int
   }
   
   // Over
   class Result {
       var value: Int
   }
   ```

2. **Clean up resources:**
   ```swift
   @nif func processFile(_ path: String) -> String? {
       guard let file = FileHandle(forReadingAtPath: path) else {
           return nil
       }
       defer { file.closeFile() }
       // ... process
   }
   ```

## Development Issues

### Hot Reload Not Working

**Issue:** Changes to Swift code don't trigger recompilation

**Solutions:**

1. **Touch the Swift file:**
   ```bash
   touch native/Sources/MyNIFs/MyNIFs.swift
   mix compile
   ```

2. **Clean build:**
   ```bash
   mix clean
   mix compile
   ```

3. **Check external resources are tracked:**
   The Swiftler module should register Swift files as external resources automatically.

### Test Failures

**Issue:** Tests fail with NIF loading errors

**Solutions:**

1. **Compile before testing:**
   ```bash
   mix swift.compile
   mix test
   ```

2. **Set test environment:**
   ```elixir
   # In test_helper.exs
   System.put_env("SWIFTLER_SKIP_COMPILATION", "false")
   ```

## Getting Help

If you encounter issues not covered here:

1. **Check logs** for detailed error messages
2. **Enable debug output**:
   ```bash
   export SWIFTLER_DEBUG=true
   ```
3. **Report issues** at [GitHub Issues](https://github.com/tuist/swiftler/issues)
4. **Include**:
   - Elixir version (`elixir --version`)
   - Swift version (`swift --version`)
   - Platform (macOS/Linux)
   - Full error message
   - Minimal reproduction code

## Common Mistakes to Avoid

1. **Forgetting to export functions in `#nifLibrary`**
2. **Mismatched function names between Swift and Elixir**
3. **Using unsupported types**
4. **Long-running operations without dirty schedulers**
5. **Not handling errors in Swift code**
6. **Assuming Swift compilation is instant** (it can take minutes)

## Quick Checklist

When things aren't working, check:

- [ ] Swift is installed and in PATH
- [ ] `Package.swift` exists in the correct location
- [ ] Swift functions are marked with `@nif`
- [ ] Functions are listed in `#nifLibrary`
- [ ] Elixir signatures match Swift functions
- [ ] Swift code has been compiled (`mix swift.compile`)
- [ ] Dynamic library exists in `priv/`
- [ ] No typos in function names