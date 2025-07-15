// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftlerExample",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "SwiftlerExample",
            type: .dynamic,
            targets: ["SwiftlerExample"]
        )
    ],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .target(
            name: "SwiftlerExample",
            dependencies: ["Swiftler"]
        )
    ]
)