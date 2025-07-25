#!/bin/bash
# Build Swift library separately to avoid long compilation times during mix compile

set -e

echo "Building Swift library (this may take 5-10 minutes on first build)..."

cd native
swift build -c release --product CalculatorNative

# Copy the built library to priv
mkdir -p ../priv
cp .build/release/libCalculatorNative.dylib ../priv/ 2>/dev/null || \
cp .build/release/libCalculatorNative.so ../priv/ 2>/dev/null

# Create symlink for macOS
if [ -f ../priv/libCalculatorNative.dylib ]; then
    cd ../priv
    ln -sf libCalculatorNative.dylib libCalculatorNative.so
fi

echo "Swift library built successfully!"
echo "You can now run 'mix test' without rebuilding Swift."