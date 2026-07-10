// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Windows)
let macDependencies: [Package.Dependency] = []
let macTargetDependencies: [Target.Dependency] = []
#else
let macDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.1"),
    .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.6.4")
]
let macTargetDependencies: [Target.Dependency] = [
    .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
    .product(name: "Sparkle", package: "Sparkle")
]
#endif

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
    dependencies: macDependencies,
    targets: [
        // Win32 C interop bridge (compiles on all platforms, but is empty on non-Windows)
        .target(
            name: "Win32Bridge",
            path: "Sources/JacqueCopy/Platform",
            sources: ["win32_bridge.c"],
            publicHeadersPath: ".",
            cSettings: [
                .define("UNICODE"),
                .define("_UNICODE")
            ],
            linkerSettings: [
                .linkedLibrary("user32"),
                .linkedLibrary("shell32"),
                .linkedLibrary("ole32")
            ]
        ),
        // Main executable target
        .executableTarget(
            name: "JacqueCopy",
            dependencies: macTargetDependencies + [
                .target(name: "Win32Bridge")
            ],
            path: "Sources/JacqueCopy",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ]
        ),
        .testTarget(
            name: "JacqueCopyTests",
            dependencies: ["JacqueCopy"],
            path: "Tests"
        )
    ]
)
