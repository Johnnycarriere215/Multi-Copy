// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JacqueCopy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "JacqueCopy",
            targets: ["JacqueCopy"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/sindresorhus/KeyboardShortcuts.git",
            from: "2.0.1"
        ),
        .package(
            url: "https://github.com/sparkle-project/Sparkle.git",
            from: "2.6.4"
        )
    ],
    targets: [
        .executableTarget(
            name: "JacqueCopy",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/JacqueCopy",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "JacqueCopyTests",
            dependencies: ["JacqueCopy"],
            path: "Tests"
        )
    ]
)
