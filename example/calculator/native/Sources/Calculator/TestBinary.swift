import Foundation
import CErlang
import SwiftlerSupport

// Test function that manually creates a binary the way Rustler does
@_cdecl("test_rustler_style_binary")
public func test_rustler_style_binary(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    let testString = "Hello from Rustler-style implementation"
    guard let data = testString.data(using: .utf8) else {
        return enif_make_badarg(env)
    }
    
    // Allocate binary on heap like Rustler
    let binaryPtr = UnsafeMutablePointer<ErlNifBinary>.allocate(capacity: 1)
    
    // Initialize it
    binaryPtr.pointee.size = 0
    binaryPtr.pointee.data = nil
    
    // Allocate the binary
    let allocResult = enif_alloc_binary(data.count, binaryPtr)
    guard allocResult != 0 else {
        binaryPtr.deallocate()
        return enif_make_badarg(env)
    }
    
    // Copy data
    data.withUnsafeBytes { bytes in
        if let baseAddress = bytes.baseAddress {
            memcpy(binaryPtr.pointee.data, baseAddress, bytes.count)
        }
    }
    
    // Create term - this takes ownership
    let term = enif_make_binary(env, binaryPtr)
    
    // DO NOT deallocate the binary pointer until AFTER enif_make_binary
    // But we DO need to deallocate the pointer itself (not the data)
    binaryPtr.deallocate()
    
    return term
}

// Another test using SwiftlerSupport
@_cdecl("test_swiftler_support_binary") 
public func test_swiftler_support_binary(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    let testString = "Hello from SwiftlerSupport"
    return BEAM.Term(testString, env: env)
}