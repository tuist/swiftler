// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CalculatorNative",
    platforms: [.macOS(.v13), .custom("linux", versionString: "0.0.0")],
    products: [
        .library(
            name: "CalculatorNative",
            type: .dynamic,
            targets: ["Calculator"]
        )
    ],
    dependencies: [
        // Use local path to avoid recompiling SwiftSyntax
        .package(name: "swiftler", path: "../../..")
    ],
    targets: [
        .target(
            name: "Calculator",
            dependencies: [
                .product(name: "Swiftler", package: "swiftler")
            ]
        )
    ]
)
