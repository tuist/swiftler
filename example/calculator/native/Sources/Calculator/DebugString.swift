import Foundation
import CErlang
import SwiftlerSupport

@_cdecl("test_string_creation")
public func test_string_creation(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    let testString = "Hello from test"
    print("[TEST] Creating BEAM.Term from string: '\(testString)'")
    
    // Method 1: Direct binary creation (current SwiftlerSupport approach)
    do {
        print("[TEST] Method 1: Using BEAM.Term initializer")
        let term = BEAM.Term(testString, env: env)
        print("[TEST] Created term: \(term)")
        
        // Verify the term is valid by trying to inspect it
        var binary = ErlNifBinary()
        if enif_inspect_binary(env, term, &binary) != 0 {
            print("[TEST] Successfully created binary term with size: \(binary.size)")
            return term
        } else {
            print("[TEST] ERROR: Created term is not a valid binary!")
        }
    }
    
    // Method 2: Manual binary creation with explicit error checking
    print("[TEST] Method 2: Manual binary creation")
    guard let data = testString.data(using: .utf8) else {
        print("[TEST] ERROR: Failed to convert string to UTF-8 data")
        return enif_make_badarg(env)
    }
    
    var binary = ErlNifBinary()
    print("[TEST] Allocating binary of size: \(data.count)")
    
    let allocResult = enif_alloc_binary(data.count, &binary)
    print("[TEST] Allocation result: \(allocResult)")
    
    guard allocResult != 0 else {
        print("[TEST] ERROR: Failed to allocate binary")
        return enif_make_badarg(env)
    }
    
    print("[TEST] Binary allocated at: \(String(describing: binary.data)), size: \(binary.size)")
    
    // Copy data
    data.withUnsafeBytes { bytes in
        if let baseAddress = bytes.baseAddress {
            print("[TEST] Copying data from: \(baseAddress)")
            memcpy(binary.data, baseAddress, bytes.count)
            print("[TEST] Data copied successfully")
        } else {
            print("[TEST] ERROR: No base address for data bytes")
        }
    }
    
    print("[TEST] Creating term from binary...")
    let term = enif_make_binary(env, &binary)
    print("[TEST] Term created: \(term)")
    
    // Verify the result
    var verifyBinary = ErlNifBinary()
    if enif_inspect_binary(env, term, &verifyBinary) != 0 {
        print("[TEST] Verification: Binary term created successfully with size: \(verifyBinary.size)")
        
        // Try to read it back
        let readData = Data(bytes: verifyBinary.data, count: verifyBinary.size)
        if let readString = String(data: readData, encoding: .utf8) {
            print("[TEST] Read back string: '\(readString)'")
        }
    } else {
        print("[TEST] ERROR: Failed to verify created binary term")
    }
    
    return term
}