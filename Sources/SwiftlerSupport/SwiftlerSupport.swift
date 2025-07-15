import Foundation
import CErlang

public enum BEAM {
    public typealias Env = OpaquePointer
    public typealias Term = ERL_NIF_TERM
    public typealias Entry = ErlNifEntry
    public typealias Func = ErlNifFunc
}

// MARK: - Environment Extensions

extension BEAM.Env {
    public func makeBadArg() -> BEAM.Term {
        return enif_make_badarg(self)
    }
    
    public func makeAtom(_ name: String) -> BEAM.Term {
        return name.withCString { cString in
            enif_make_atom(self, cString)
        }
    }
    
    public func makeTuple(_ terms: [BEAM.Term]) -> BEAM.Term {
        return terms.withUnsafeBufferPointer { buffer in
            enif_make_tuple_from_array(self, buffer.baseAddress, UInt32(buffer.count))
        }
    }
    
    public func makeOk(_ term: BEAM.Term) -> BEAM.Term {
        let okAtom = makeAtom("ok")
        return makeTuple([okAtom, term])
    }
    
    public func makeError(_ term: BEAM.Term) -> BEAM.Term {
        let errorAtom = makeAtom("error")
        return makeTuple([errorAtom, term])
    }
}

// MARK: - Type Conversions

// Integer conversions
extension Int32 {
    public init?(_ term: BEAM.Term, env: BEAM.Env) {
        var value: Int32 = 0
        guard enif_get_int(env, term, &value) != 0 else { return nil }
        self = value
    }
}

extension Int64 {
    public init?(_ term: BEAM.Term, env: BEAM.Env) {
        var value: Int = 0
        guard enif_get_long(env, term, &value) != 0 else { return nil }
        self = Int64(value)
    }
}

extension Int {
    public init?(_ term: BEAM.Term, env: BEAM.Env) {
        if let value = Int32(term, env: env) {
            self = Int(value)
        } else {
            return nil
        }
    }
}

// Double conversion
extension Double {
    public init?(_ term: BEAM.Term, env: BEAM.Env) {
        var value: Double = 0
        guard enif_get_double(env, term, &value) != 0 else { return nil }
        self = value
    }
}

// String conversion
extension String {
    public init?(_ term: BEAM.Term, env: BEAM.Env) {
        var binary = ErlNifBinary()
        guard enif_inspect_binary(env, term, &binary) != 0 else {
            // Try as string list
            var length: UInt32 = 0
            guard enif_get_list_length(env, term, &length) != 0 else { return nil }
            
            var chars = [CChar](repeating: 0, count: Int(length) + 1)
            guard enif_get_string(env, term, &chars, UInt32(chars.count), ERL_NIF_LATIN1) > 0 else { return nil }
            
            let nullTerminated = chars.prefix(while: { $0 != 0 })
            self = String(decoding: nullTerminated.map { UInt8(bitPattern: $0) }, as: UTF8.self)
            return
        }
        
        let data = Data(bytes: binary.data, count: binary.size)
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        self = string
    }
}

// Data conversion
extension Data {
    public init?(_ term: BEAM.Term, env: BEAM.Env) {
        var binary = ErlNifBinary()
        guard enif_inspect_binary(env, term, &binary) != 0 else { return nil }
        self = Data(bytes: binary.data, count: binary.size)
    }
}

// Bool conversion
extension Bool {
    public init?(_ term: BEAM.Term, env: BEAM.Env) {
        var atomLength: UInt32 = 0
        guard enif_get_atom_length(env, term, &atomLength, ERL_NIF_LATIN1) != 0 else { return nil }
        
        var atomBuffer = [CChar](repeating: 0, count: Int(atomLength) + 1)
        guard enif_get_atom(env, term, &atomBuffer, UInt32(atomBuffer.count), ERL_NIF_LATIN1) > 0 else { return nil }
        
        let nullTerminated = atomBuffer.prefix(while: { $0 != 0 })
        let atomString = String(decoding: nullTerminated.map { UInt8(bitPattern: $0) }, as: UTF8.self)
        switch atomString {
        case "true":
            self = true
        case "false":
            self = false
        default:
            return nil
        }
    }
}

// MARK: - Term Creation

extension BEAM.Term {
    public init(_ int: Int, env: BEAM.Env) {
        self = enif_make_int(env, Int32(int))
    }
    
    public init(_ int: Int32, env: BEAM.Env) {
        self = enif_make_int(env, int)
    }
    
    public init(_ int: Int64, env: BEAM.Env) {
        self = enif_make_long(env, Int(int))
    }
    
    public init(_ double: Double, env: BEAM.Env) {
        self = enif_make_double(env, double)
    }
    
    public init(_ string: String, env: BEAM.Env) {
        let data = string.data(using: .utf8) ?? Data()
        self = BEAM.Term(data, env: env)
    }
    
    public init(_ data: Data, env: BEAM.Env) {
        var binaryRef = ErlNifBinary()
        enif_alloc_binary(data.count, &binaryRef)
        
        if data.count > 0 {
            data.withUnsafeBytes { bytes in
                if let baseAddress = bytes.baseAddress {
                    memcpy(binaryRef.data, baseAddress, bytes.count)
                }
            }
        }
        
        let term = enif_make_binary(env, &binaryRef)
        self = term
    }
    
    public init(_ bool: Bool, env: BEAM.Env) {
        let atomName = bool ? "true" : "false"
        self = atomName.withCString { cString in
            enif_make_atom(env, cString)
        }
    }
}