// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftlerNative",
    products: [
        .library(
            name: "SwiftlerNative",
            type: .static,
            targets: ["SwiftlerNative"]
        )
    ],
    targets: [
        .target(
            name: "SwiftlerNative"
        )
    ]
)
