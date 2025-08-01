import Foundation
import CErlang
import SwiftlerSupport

// Completely manual implementation to test
@_cdecl("manual_simple_string_test")
public func manual_simple_string_test(
    env: OpaquePointer?,
    argc: Int32,
    argv: UnsafePointer<ERL_NIF_TERM>?
) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    // Call the actual simple_string_test function
    let result = simple_string_test()
    
    // Convert using BEAM.Term
    return BEAM.Term(result, env: env)
}