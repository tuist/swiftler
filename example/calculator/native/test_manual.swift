import Foundation
@_implementationOnly import CErlang

// Manual implementation to test string handling
@_cdecl("test_greet_manual")
public func test_greet_manual(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env, let argv = argv, argc == 1 else {
        return enif_make_badarg(env)
    }
    
    // Try to get the string
    print("test_greet_manual called with argc: \(argc)")
    
    let nameArg = argv[0]
    
    // Test if it's a binary
    var binary = ErlNifBinary()
    if enif_inspect_binary(env, nameArg, &binary) != 0 {
        print("Input is a binary with size: \(binary.size)")
        
        // Try to create a string from the binary
        let data = Data(bytes: binary.data, count: binary.size)
        if let str = String(data: data, encoding: .utf8) {
            print("Successfully decoded string: '\(str)'")
            
            // Create response
            let response = "Hello, \(str)!"
            print("Creating response: '\(response)'")
            
            // Convert back to term manually
            let responseData = response.data(using: .utf8) ?? Data()
            var binaryRef = ErlNifBinary()
            
            if enif_alloc_binary(responseData.count, &binaryRef) != 0 {
                responseData.withUnsafeBytes { bytes in
                    if let baseAddress = bytes.baseAddress {
                        memcpy(binaryRef.data, baseAddress, bytes.count)
                    }
                }
                let term = enif_make_binary(env, &binaryRef)
                print("Created term successfully")
                return term
            } else {
                print("Failed to allocate binary")
                return enif_make_badarg(env)
            }
        } else {
            print("Failed to decode UTF-8 string from binary")
        }
    } else {
        print("Input is not a binary, trying as string list...")
        
        // Try as string list
        var length: UInt32 = 0
        if enif_get_list_length(env, nameArg, &length) != 0 {
            print("Input is a list with length: \(length)")
        }
    }
    
    print("Returning badarg")
    return enif_make_badarg(env)
}

// Add to exports
@_cdecl("test_init")
public func test_init() -> UnsafePointer<ErlNifEntry>? {
    print("test_init called")
    
    let funcs = UnsafeMutablePointer<ErlNifFunc>.allocate(capacity: 2)
    
    // Setup test function
    funcs[0] = ErlNifFunc(
        name: strdup("test_greet_manual"),
        arity: 1,
        fptr: test_greet_manual,
        flags: 0
    )
    
    // Null terminator
    funcs[1] = ErlNifFunc(
        name: nil,
        arity: 0,
        fptr: nil,
        flags: 0
    )
    
    let entry = UnsafeMutablePointer<ErlNifEntry>.allocate(capacity: 1)
    entry.pointee = ErlNifEntry(
        major: 2,
        minor: 16,
        name: strdup("Elixir.TestManual"),
        num_of_funcs: 1,
        funcs: funcs,
        load: nil,
        reload: nil,
        upgrade: nil,
        unload: nil,
        vm_variant: strdup("beam.vanilla"),
        options: 1,
        sizeof_ErlNifResourceTypeInit: MemoryLayout<ErlNifResourceTypeInit>.size,
        min_erts: strdup("erts-12.0")
    )
    
    return UnsafePointer(entry)
}