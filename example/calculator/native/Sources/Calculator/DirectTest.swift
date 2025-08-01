import Foundation
import CErlang
import SwiftlerSupport

// Direct test without using macros
@_cdecl("direct_test_beam_term")
public func direct_test_beam_term(
    env: OpaquePointer?,
    argc: Int32,
    argv: UnsafePointer<ERL_NIF_TERM>?
) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    // Test 1: Create a string using BEAM.Term
    let str = "Test string"
    let term1 = BEAM.Term(str, env: env)
    
    // Verify it's valid
    var binary = ErlNifBinary()
    if enif_inspect_binary(env, term1, &binary) != 0 {
        print("Successfully created binary with size: \(binary.size)")
    } else {
        print("Failed to create valid binary!")
    }
    
    return term1
}