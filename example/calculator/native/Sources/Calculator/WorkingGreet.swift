import Foundation
import Swiftler
import CErlang
import SwiftlerSupport

// Manual implementation that should work
@_cdecl("working_greet")
public func working_greet(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env, argc == 1, let argv = argv else {
        return enif_make_badarg(env!)
    }
    
    // Get input string
    var binary = ErlNifBinary()
    guard enif_inspect_binary(env, argv[0], &binary) != 0 else {
        return enif_make_badarg(env)
    }
    
    let data = Data(bytes: binary.data, count: binary.size)
    guard let name = String(data: data, encoding: .utf8) else {
        return enif_make_badarg(env)
    }
    
    // Call the greet function
    let result = greet(name)
    
    // Convert result - try the simplest possible approach
    guard let resultData = result.data(using: .utf8) else {
        return enif_make_badarg(env)
    }
    
    // Allocate new binary
    var resultBinary = ErlNifBinary()
    guard enif_alloc_binary(resultData.count, &resultBinary) != 0 else {
        return enif_make_badarg(env)
    }
    
    // Copy data - use a different approach
    resultData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
        if let baseAddress = bytes.baseAddress {
            _ = memcpy(resultBinary.data, baseAddress, bytes.count)
        }
    }
    
    // Make binary - this takes ownership
    return enif_make_binary(env, &resultBinary)
}