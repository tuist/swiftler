// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Swiftler",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
    products: [
        .library(
            name: "Swiftler",
            targets: ["Swiftler"]
        ),
        .library(
            name: "SwiftlerSupport",
            targets: ["SwiftlerSupport"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .target(
            name: "Swiftler",
            dependencies: [
                "SwiftlerMacros",
                "SwiftlerSupport",
            ]
        ),
        .target(
            name: "SwiftlerSupport",
            dependencies: ["CErlang"]
        ),
        .macro(
            name: "SwiftlerMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "CErlang",
            path: "Sources/CErlang",
            publicHeadersPath: "."
        ),
    ]
)
