import Foundation
import Swiftler
import CErlang

// Manual implementation that mimics what the macro should generate
@_cdecl("manual_greet_thunk")
public func manual_greet_thunk(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    print("[THUNK] Called with env: \(String(describing: env)), argc: \(argc), argv: \(String(describing: argv))")
    
    guard let env = env, argc == 1, let argv = argv else {
        print("[THUNK] Bad arguments")
        return enif_make_badarg(env!)
    }
    
    // Extract String parameter
    print("[THUNK] Extracting parameter...")
    guard let param0 = String(argv[0], env: env) else {
        print("[THUNK] Failed to extract string parameter")
        return enif_make_badarg(env)
    }
    print("[THUNK] Parameter extracted: '\(param0)'")
    
    // Call the actual function
    print("[THUNK] Calling greet function...")
    let result = greet(param0)
    print("[THUNK] Function returned: '\(result)'")
    
    // Convert result to Erlang term
    print("[THUNK] Converting result to Erlang term...")
    let resultData = result.data(using: .utf8) ?? Data()
    print("[THUNK] Result data size: \(resultData.count)")
    
    var resultBinary = ErlNifBinary()
    print("[THUNK] Allocating binary...")
    if enif_alloc_binary(resultData.count, &resultBinary) != 0 {
        print("[THUNK] Binary allocated successfully")
        resultData.withUnsafeBytes { bytes in
            if let baseAddress = bytes.baseAddress {
                print("[THUNK] Copying \(bytes.count) bytes...")
                memcpy(resultBinary.data, baseAddress, bytes.count)
                print("[THUNK] Copy complete")
            }
        }
        print("[THUNK] Making binary term...")
        let term = enif_make_binary(env, &resultBinary)
        print("[THUNK] Term created: \(term)")
        print("[THUNK] Returning successfully")
        return term
    } else {
        print("[THUNK] Failed to allocate binary")
        return enif_make_badarg(env)
    }
}