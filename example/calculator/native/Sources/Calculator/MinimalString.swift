import Foundation
import CErlang

// Minimal string test without any Swift abstractions
@_cdecl("minimal_string_test")
public func minimal_string_test(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    // Create a simple string
    let str = "Hello"
    let bytes = [UInt8](str.utf8)
    
    // Allocate binary
    var binary = ErlNifBinary()
    guard enif_alloc_binary(bytes.count, &binary) != 0 else {
        return enif_make_badarg(env)
    }
    
    // Copy bytes
    for i in 0..<bytes.count {
        binary.data[i] = bytes[i]
    }
    
    // Make binary term
    return enif_make_binary(env, &binary)
}