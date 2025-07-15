import Darwin
import Foundation
import CErlang

// Basic C interface functions for Erlang NIFs
@_cdecl("add_nif")
func add_nif(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env, let argv = argv else { return 0 }
    var a: Int32 = 0
    var b: Int32 = 0
    
    guard enif_get_int(env, argv[0], &a) != 0,
          enif_get_int(env, argv[1], &b) != 0 else {
        return enif_make_badarg(env)
    }
    
    let result = a + b
    return enif_make_int(env, result)
}

@_cdecl("multiply_nif")
func multiply_nif(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env, let argv = argv else { return 0 }
    var a: Int32 = 0
    var b: Int32 = 0
    
    guard enif_get_int(env, argv[0], &a) != 0,
          enif_get_int(env, argv[1], &b) != 0 else {
        return enif_make_badarg(env)
    }
    
    let result = a * b
    return enif_make_int(env, result)
}

@_cdecl("greet_nif")
func greet_nif(env: OpaquePointer?, argc: Int32, argv: UnsafePointer<ERL_NIF_TERM>?) -> ERL_NIF_TERM {
    guard let env = env, let argv = argv else { return 0 }
    var binary = ErlNifBinary()
    guard enif_inspect_binary(env, argv[0], &binary) != 0 else {
        return enif_make_badarg(env)
    }
    
    let nameData = Data(bytes: binary.data, count: binary.size)
    guard let name = String(data: nameData, encoding: .utf8) else {
        return enif_make_badarg(env)
    }
    
    let greeting = "Hello, \(name) from Swift!"
    let greetingData = greeting.data(using: .utf8) ?? Data()
    
    var resultBinary = ErlNifBinary()
    enif_alloc_binary(greetingData.count, &resultBinary)
    greetingData.withUnsafeBytes { bytes in
        if let baseAddress = bytes.baseAddress {
            memcpy(resultBinary.data, baseAddress, bytes.count)
        }
    }
    
    return enif_make_binary(env, &resultBinary)
}

// Global storage for function list
private let globalFuncs: UnsafeMutablePointer<ErlNifFunc> = {
    let ptr = UnsafeMutablePointer<ErlNifFunc>.allocate(capacity: 3)
    ptr[0] = ErlNifFunc(name: strdup("add"), arity: 2, fptr: add_nif, flags: 0)
    ptr[1] = ErlNifFunc(name: strdup("multiply"), arity: 2, fptr: multiply_nif, flags: 0)
    ptr[2] = ErlNifFunc(name: strdup("greet"), arity: 1, fptr: greet_nif, flags: 0)
    return ptr
}()

// Global storage for entry
private let globalEntry: UnsafeMutablePointer<ErlNifEntry> = {
    let ptr = UnsafeMutablePointer<ErlNifEntry>.allocate(capacity: 1)
    ptr.pointee = ErlNifEntry(
        major: ERL_NIF_MAJOR_VERSION,
        minor: ERL_NIF_MINOR_VERSION,
        name: strdup("Elixir.SwiftlerNative"),
        num_of_funcs: 3,
        funcs: globalFuncs,
        load: nil,
        reload: nil,
        upgrade: nil,
        unload: nil,
        vm_variant: strdup("beam.vanilla"),
        options: 1,
        sizeof_ErlNifResourceTypeInit: MemoryLayout<ErlNifResourceTypeInit>.size,
        min_erts: strdup("erts-12.0")
    )
    return ptr
}()

// NIF entry point
@_cdecl("nif_init")
func nif_init() -> UnsafePointer<ErlNifEntry>? {
    return UnsafePointer(globalEntry)
}