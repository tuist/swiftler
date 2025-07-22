// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CalculatorNative",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "CalculatorNative",
            type: .dynamic,
            targets: ["Calculator"]
        )
    ],
    dependencies: [
        .package(path: "../../..")
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
