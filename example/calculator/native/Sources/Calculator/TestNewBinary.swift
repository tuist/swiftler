import Foundation
import CErlang
import SwiftlerSupport

// Test using enif_make_new_binary as suggested by research
@_cdecl("test_new_binary")
public func test_new_binary(
    env: OpaquePointer?,
    argc: Int32,
    argv: UnsafePointer<ERL_NIF_TERM>?
) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    let testString = "Test with new binary"
    guard let data = testString.data(using: .utf8) else {
        return enif_make_badarg(env)
    }
    
    // Try using enif_make_new_binary
    var binaryPtr: UnsafeMutablePointer<UInt8>? = nil
    let term = enif_make_new_binary(env, data.count, &binaryPtr)
    
    guard let ptr = binaryPtr else {
        return enif_make_badarg(env)
    }
    
    // Copy data to the binary
    data.withUnsafeBytes { bytes in
        if let baseAddress = bytes.baseAddress {
            memcpy(ptr, baseAddress, data.count)
        }
    }
    
    return term
}