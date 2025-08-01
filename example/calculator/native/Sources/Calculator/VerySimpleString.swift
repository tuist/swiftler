import Foundation
import CErlang

// The absolute simplest string function possible
@_cdecl("very_simple_string")
public func very_simple_string(
    env: OpaquePointer?,
    argc: Int32,
    argv: UnsafePointer<ERL_NIF_TERM>?
) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    // Just create a static string
    let str = "test"
    let data = str.data(using: .utf8)!
    
    // Use the most basic binary creation
    var binary = ErlNifBinary()
    if enif_alloc_binary(data.count, &binary) == 0 {
        return enif_make_badarg(env)
    }
    
    // Copy bytes one by one to avoid any closure issues
    for i in 0..<data.count {
        binary.data[i] = data[i]
    }
    
    return enif_make_binary(env, &binary)
}