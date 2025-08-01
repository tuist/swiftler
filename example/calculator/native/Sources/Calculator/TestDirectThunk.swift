import Foundation
import CErlang
import SwiftlerSupport

// Direct implementation of what the macro should generate
@_cdecl("direct_simple_string_test")
public func direct_simple_string_test(
    env: OpaquePointer?,
    argc: Int32,
    argv: UnsafePointer<ERL_NIF_TERM>?
) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    // Call the actual function
    let result = simple_string_test()
    
    // Convert string to UTF-8 data
    guard let data = result.data(using: .utf8) else {
        return enif_make_badarg(env)
    }
    
    // Allocate binary
    var binary = ErlNifBinary()
    guard enif_alloc_binary(data.count, &binary) != 0 else {
        return enif_make_badarg(env)
    }
    
    // Copy data
    if data.count > 0 {
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            if let baseAddress = bytes.baseAddress {
                _ = memcpy(binary.data, baseAddress, bytes.count)
            }
        }
    }
    
    // Create term - this transfers ownership
    return enif_make_binary(env, &binary)
}