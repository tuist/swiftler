import Foundation
import CErlang

// Debug version of greet with extensive logging
@_cdecl("debug_greet")
public func debug_greet(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    print("=== debug_greet called ===")
    print("env: \(String(describing: env))")
    print("argc: \(argc)")
    print("argv: \(String(describing: argv))")
    
    guard let env = env else {
        print("ERROR: env is nil")
        return 0
    }
    
    guard let argv = argv else {
        print("ERROR: argv is nil")
        return enif_make_badarg(env)
    }
    
    guard argc == 1 else {
        print("ERROR: argc is \(argc), expected 1")
        return enif_make_badarg(env)
    }
    
    print("Step 1: Getting input term")
    let inputTerm = argv[0]
    print("Input term value: \(inputTerm)")
    
    print("Step 2: Checking if input is a binary")
    var binary = ErlNifBinary()
    let isBinary = enif_inspect_binary(env, inputTerm, &binary)
    print("Is binary result: \(isBinary)")
    
    if isBinary != 0 {
        print("Binary size: \(binary.size)")
        print("Binary data pointer: \(String(describing: binary.data))")
        
        print("Step 3: Creating Data from binary")
        let data = Data(bytes: binary.data, count: binary.size)
        print("Data created, size: \(data.count)")
        
        print("Step 4: Converting to String")
        if let str = String(data: data, encoding: .utf8) {
            print("String decoded successfully: '\(str)'")
            
            print("Step 5: Creating response string")
            let response = "Hello, \(str)!"
            print("Response: '\(response)'")
            
            print("Step 6: Converting response to data")
            guard let responseData = response.data(using: .utf8) else {
                print("ERROR: Failed to convert response to UTF-8 data")
                return enif_make_badarg(env)
            }
            print("Response data size: \(responseData.count)")
            
            print("Step 7: Allocating binary for response")
            var responseBinary = ErlNifBinary()
            let allocResult = enif_alloc_binary(responseData.count, &responseBinary)
            print("Alloc result: \(allocResult)")
            
            if allocResult == 0 {
                print("ERROR: Failed to allocate binary")
                return enif_make_badarg(env)
            }
            
            print("Step 8: Copying data to binary")
            responseData.withUnsafeBytes { bytes in
                if let baseAddress = bytes.baseAddress {
                    print("Copying \(bytes.count) bytes from \(baseAddress) to \(String(describing: responseBinary.data))")
                    memcpy(responseBinary.data, baseAddress, bytes.count)
                    print("Copy completed")
                } else {
                    print("ERROR: No base address for response data")
                }
            }
            
            print("Step 9: Creating term from binary")
            let resultTerm = enif_make_binary(env, &responseBinary)
            print("Result term: \(resultTerm)")
            
            print("=== debug_greet returning successfully ===")
            return resultTerm
        } else {
            print("ERROR: Failed to decode UTF-8 string")
        }
    } else {
        print("Input is not a binary, checking if it's a list...")
        var length: UInt32 = 0
        if enif_get_list_length(env, inputTerm, &length) != 0 {
            print("Input is a list with length: \(length)")
        } else {
            print("Input is neither binary nor list")
        }
    }
    
    print("=== debug_greet returning badarg ===")
    return enif_make_badarg(env)
}