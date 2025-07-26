#!/bin/bash
# check_nif_symbols.sh - Script to verify NIF symbols in a dynamic library

LIBRARY=$1
PLATFORM=$(uname)

if [ -z "$LIBRARY" ]; then
    echo "Usage: $0 <path/to/library.dylib|.so>"
    exit 1
fi

if [ ! -f "$LIBRARY" ]; then
    echo "Error: File not found: $LIBRARY"
    exit 1
fi

echo "Checking NIF symbols in: $LIBRARY"
echo "Platform: $PLATFORM"
echo "File type: $(file -b "$LIBRARY")"
echo "---"

if [ "$PLATFORM" = "Darwin" ]; then
    # macOS
    echo "Looking for _nif_init and ___swiftler_nif_thunk_* symbols..."
    echo ""
    echo "Exported symbols:"
    SYMBOLS=$(nm -gU "$LIBRARY" 2>/dev/null | grep -E "T _nif_init|T ___swiftler_nif_thunk")
    if [ -z "$SYMBOLS" ]; then
        echo "  No NIF symbols found!"
        echo ""
        echo "All exported text symbols:"
        nm -gU "$LIBRARY" 2>/dev/null | grep "T " | head -10
        echo ""
        echo "Checking all symbols (not just exported):"
        nm "$LIBRARY" 2>/dev/null | grep -E "_nif_init|__swiftler_nif_thunk" | head -10
    else
        echo "$SYMBOLS"
        echo ""
        echo "Total NIF symbols found: $(echo "$SYMBOLS" | wc -l)"
    fi
else
    # Linux
    echo "Looking for nif_init and __swiftler_nif_thunk_* symbols..."
    echo ""
    echo "Dynamic symbols:"
    SYMBOLS=$(nm -D "$LIBRARY" 2>/dev/null | grep -E "T nif_init|T __swiftler_nif_thunk")
    if [ -z "$SYMBOLS" ]; then
        echo "  No NIF symbols found!"
        echo ""
        echo "All dynamic text symbols:"
        nm -D "$LIBRARY" 2>/dev/null | grep "T " | head -10
        echo ""
        echo "Checking all symbols:"
        nm "$LIBRARY" 2>/dev/null | grep -E "nif_init|__swiftler_nif_thunk" | head -10
    else
        echo "$SYMBOLS"
        echo ""
        echo "Total NIF symbols found: $(echo "$SYMBOLS" | wc -l)"
    fi
fi

echo ""
echo "Symbol table info:"
if [ "$PLATFORM" = "Darwin" ]; then
    otool -l "$LIBRARY" | grep -A5 "SYMTAB" | grep -E "nsyms|nextdefsym"
else
    readelf -h "$LIBRARY" 2>/dev/null | grep "Section header string table index"
fi