import Foundation
import CErlang

// Completely manual implementation without any Swiftler code
@_cdecl("completely_manual_string")
public func completely_manual_string(
    env: OpaquePointer?,
    argc: Int32,
    argv: UnsafePointer<ERL_NIF_TERM>?
) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    // Create a simple string
    let str = "Manual test string"
    let utf8 = str.utf8
    let bytes = Array(utf8)
    
    // Allocate binary
    var binary = ErlNifBinary()
    guard enif_alloc_binary(bytes.count, &binary) != 0 else {
        return 0
    }
    
    // Copy bytes manually
    for i in 0..<bytes.count {
        binary.data[i] = bytes[i]
    }
    
    // Return binary
    return enif_make_binary(env, &binary)
}