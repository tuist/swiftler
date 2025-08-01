import Foundation
import CErlang
import SwiftlerSupport

// Debug version of the thunk to see what's happening
@_cdecl("debug_thunk_simple_string_test")
public func debug_thunk_simple_string_test(
    env: OpaquePointer?,
    argc: Int32,
    argv: UnsafePointer<ERL_NIF_TERM>?
) -> ERL_NIF_TERM {
    print("[DEBUG_THUNK] Called with env: \(String(describing: env)), argc: \(argc)")
    
    guard let env = env else { 
        print("[DEBUG_THUNK] No env!")
        return 0 
    }
    
    print("[DEBUG_THUNK] About to call simple_string_test()...")
    let result = simple_string_test()
    print("[DEBUG_THUNK] Got result: '\(result)'")
    
    print("[DEBUG_THUNK] Creating BEAM.Term...")
    let term = BEAM.Term(result, env: env)
    print("[DEBUG_THUNK] Created term: \(term)")
    
    return term
}