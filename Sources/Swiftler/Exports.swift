import SwiftlerSupport

@attached(peer, names: prefixed(__swiftler_nif_thunk_))
public macro nif() = #externalMacro(module: "SwiftlerMacros", type: "NIFMacro")

@freestanding(declaration, names: named(nif_init))
public macro nifLibrary(name: String, functions: [Any]) = #externalMacro(module: "SwiftlerMacros", type: "NIFLibraryMacro")