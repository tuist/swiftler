@_exported import SwiftlerSupport
@_exported import CErlang

/// The main Swiftler module that provides macros for creating NIF libraries.
///
/// Usage:
/// ```swift
/// import Swiftler
///
/// #nifLibrary(name: "adder", functions: [add(_:_:)])
///
/// @nif func add(_ a: Int, _ b: Int) -> Int {
///     a + b
/// }
/// ```