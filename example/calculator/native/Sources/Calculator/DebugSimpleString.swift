import Foundation
import CErlang
import SwiftlerSupport

// Debug version of simple_string_test to understand what's happening
@_cdecl("debug_simple_string_test")
public func debug_simple_string_test(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    print("[DEBUG_SIMPLE] Called with env: \(String(describing: env)), argc: \(argc)")
    
    guard let env = env else {
        print("[DEBUG_SIMPLE] No env!")
        return 0
    }
    
    print("[DEBUG_SIMPLE] About to create string...")
    let result = "Simple test string"
    print("[DEBUG_SIMPLE] String created: '\(result)'")
    
    print("[DEBUG_SIMPLE] Converting to data...")
    guard let data = result.data(using: .utf8) else {
        print("[DEBUG_SIMPLE] Failed to convert to UTF-8!")
        return enif_make_badarg(env)
    }
    print("[DEBUG_SIMPLE] Data size: \(data.count)")
    
    print("[DEBUG_SIMPLE] Allocating binary...")
    var binary = ErlNifBinary()
    let allocResult = enif_alloc_binary(data.count, &binary)
    print("[DEBUG_SIMPLE] Allocation result: \(allocResult)")
    
    guard allocResult != 0 else {
        print("[DEBUG_SIMPLE] Failed to allocate!")
        return enif_make_badarg(env)
    }
    
    print("[DEBUG_SIMPLE] Binary allocated, size: \(binary.size)")
    
    print("[DEBUG_SIMPLE] Copying data...")
    data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
        if let baseAddress = bytes.baseAddress {
            print("[DEBUG_SIMPLE] Copying from \(baseAddress) to \(String(describing: binary.data))")
            memcpy(binary.data, baseAddress, bytes.count)
            print("[DEBUG_SIMPLE] Copy complete")
        } else {
            print("[DEBUG_SIMPLE] No base address!")
        }
    }
    
    print("[DEBUG_SIMPLE] Creating term...")
    let term = enif_make_binary(env, &binary)
    print("[DEBUG_SIMPLE] Term created: \(term)")
    
    print("[DEBUG_SIMPLE] Returning...")
    return term
}