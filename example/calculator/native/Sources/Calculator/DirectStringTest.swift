import Foundation
import CErlang

// Direct implementation without using BEAM.Term
@_cdecl("direct_string_test")
public func direct_string_test(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env else { return 0 }
    
    let testString = "Hello Direct"
    guard let data = testString.data(using: .utf8) else {
        return enif_make_badarg(env)
    }
    
    var binary = ErlNifBinary()
    
    guard enif_alloc_binary(data.count, &binary) != 0 else {
        return enif_make_badarg(env)
    }
    
    data.withUnsafeBytes { bytes in
        if let src = bytes.baseAddress {
            memcpy(binary.data, src, data.count)
        }
    }
    
    return enif_make_binary(env, &binary)
}