import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct SwiftlerMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        NIFMacro.self,
        NIFLibraryMacro.self
    ]
}

public struct NIFMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroError.message("@nif can only be applied to functions")
        }
        
        let functionName = funcDecl.name.text
        let thunkName = "__swiftler_nif_thunk_\(functionName)"
        
        // Extract parameters
        let parameters = funcDecl.signature.parameterClause.parameters
        let hasEnvParam = parameters.first?.firstName.text == "env"
        let startIndex = hasEnvParam ? 1 : 0
        
        // Generate parameter extraction code
        var parameterExtractions: [String] = []
        var parameterNames: [String] = []
        
        for (index, param) in parameters.dropFirst(startIndex).enumerated() {
            let paramName = param.secondName?.text ?? param.firstName.text
            let paramType = param.type.description.trimmingCharacters(in: .whitespaces)
            
            parameterNames.append(paramName)
            
            // Generate appropriate extraction based on type
            let extraction: String
            switch paramType {
            case "Int", "Int32":
                extraction = """
                    var \(paramName): Int32 = 0
                    guard enif_get_int(env, argv[\(index)], &\(paramName)) != 0 else {
                        return enif_make_badarg(env)
                    }
                    """
            case "String":
                extraction = """
                    var \(paramName)Binary = ErlNifBinary()
                    guard enif_inspect_binary(env, argv[\(index)], &\(paramName)Binary) != 0 else {
                        return enif_make_badarg(env)
                    }
                    let \(paramName)Data = Data(bytes: \(paramName)Binary.data, count: \(paramName)Binary.size)
                    guard let \(paramName) = String(data: \(paramName)Data, encoding: .utf8) else {
                        return enif_make_badarg(env)
                    }
                    """
            default:
                extraction = """
                    // Unsupported type: \(paramType)
                    return enif_make_badarg(env)
                    """
            }
            
            parameterExtractions.append(extraction)
        }
        
        // Generate function call
        let callArguments = hasEnvParam 
            ? ["env: env"] + parameterNames.map { "\($0)" }
            : parameterNames.map { "\($0)" }
        let functionCall = "\(functionName)(\(callArguments.joined(separator: ", ")))"
        
        // Generate result conversion
        let resultConversion: String
        if let returnType = funcDecl.signature.returnClause?.type {
            let returnTypeStr = returnType.description.trimmingCharacters(in: .whitespaces)
            switch returnTypeStr {
            case "Int", "Int32":
                resultConversion = """
                    let result = \(functionCall)
                    return enif_make_int(env, result)
                    """
            case "String":
                resultConversion = """
                    let result = \(functionCall)
                    let resultData = result.data(using: .utf8) ?? Data()
                    var resultBinary = ErlNifBinary()
                    enif_alloc_binary(resultData.count, &resultBinary)
                    resultData.withUnsafeBytes { bytes in
                        if let baseAddress = bytes.baseAddress {
                            memcpy(resultBinary.data, baseAddress, bytes.count)
                        }
                    }
                    return enif_make_binary(env, &resultBinary)
                    """
            default:
                resultConversion = """
                    let result = \(functionCall)
                    return enif_make_atom(env, "unsupported_return_type")
                    """
            }
        } else {
            resultConversion = """
                \(functionCall)
                return enif_make_atom(env, "ok")
                """
        }
        
        // Generate thunk function
        let thunkFunction = """
            @_cdecl("\(thunkName)")
            func \(thunkName)(
                env: OpaquePointer?,
                argc: Int32,
                argv: UnsafePointer<ERL_NIF_TERM>?
            ) -> ERL_NIF_TERM {
                guard let env = env, let argv = argv else { return 0 }
                
                \(parameterExtractions.joined(separator: "\n    "))
                
                \(resultConversion)
            }
            """
        
        return [DeclSyntax(stringLiteral: thunkFunction)]
    }
}

public struct NIFLibraryMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract arguments
        guard node.argumentList.count >= 2,
              let nameExpr = node.argumentList.first?.expression,
              let functionsExpr = node.argumentList.dropFirst().first?.expression else {
            throw MacroError.message("nifLibrary requires name and functions arguments")
        }
        
        // Extract library name
        let libraryName = nameExpr.description
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        
        // Extract function names and arity from array literal
        var functionInfos: [(name: String, arity: Int)] = []
        if let arrayExpr = functionsExpr.as(ArrayExprSyntax.self) {
            for element in arrayExpr.elements {
                let funcExpr = element.expression.description
                    .trimmingCharacters(in: .whitespaces)
                
                // Extract function name
                let funcName = funcExpr
                    .replacingOccurrences(of: "(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .replacingOccurrences(of: "_:", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: " ", with: "")
                
                // Count underscores for arity
                let arity = funcExpr.filter { $0 == "_" }.count
                
                functionInfos.append((name: funcName, arity: arity))
            }
        }
        
        // Generate function entries
        let functionEntries = functionInfos.map { info in
            """
                ErlNifFunc(
                    name: strdup("\(info.name)"),
                    arity: \(info.arity),
                    fptr: __swiftler_nif_thunk_\(info.name),
                    flags: 0
                )
                """
        }.joined(separator: ",\n        ")
        
        // Generate nif_init function
        let initFunction = """
            @_cdecl("nif_init")
            func nif_init() -> UnsafePointer<ErlNifEntry>? {
                let funcs: [ErlNifFunc] = [
                    \(functionEntries)
                ]
                
                let entry = UnsafeMutablePointer<ErlNifEntry>.allocate(capacity: 1)
                entry.pointee = ErlNifEntry(
                    major: ERL_NIF_MAJOR_VERSION,
                    minor: ERL_NIF_MINOR_VERSION,
                    name: strdup("\(libraryName)"),
                    num_of_funcs: Int32(funcs.count),
                    funcs: UnsafeMutablePointer(mutating: funcs),
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
            """
        
        return [DeclSyntax(stringLiteral: initFunction)]
    }
}

enum MacroError: Error, CustomStringConvertible {
    case message(String)
    
    var description: String {
        switch self {
        case .message(let text):
            return text
        }
    }
}