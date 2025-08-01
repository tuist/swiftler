import Foundation
import CErlang
import SwiftlerSupport

// Direct test of BEAM.Term string conversion
@_cdecl("test_beam_term_string")
public func test_beam_term_string(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env else {
        return enif_make_badarg(env!)
    }
    
    // Test creating a BEAM.Term from a string
    let testString = "Hello from BEAM.Term"
    print("[TEST_BEAM] Creating term from string: '\(testString)'")
    
    // Use our fixed BEAM.Term initializer
    let term = BEAM.Term(testString, env: env)
    print("[TEST_BEAM] Created term: \(term)")
    
    // Verify the term
    var binary = ErlNifBinary()
    if enif_inspect_binary(env, term, &binary) != 0 {
        print("[TEST_BEAM] Successfully created binary term with size: \(binary.size)")
        let data = Data(bytes: binary.data, count: binary.size)
        if let readString = String(data: data, encoding: .utf8) {
            print("[TEST_BEAM] Read back string: '\(readString)'")
        }
    } else {
        print("[TEST_BEAM] ERROR: Created term is not a valid binary!")
    }
    
    return term
}