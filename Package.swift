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
        // Win32 C interop bridge. Its source is fully guarded by `#ifdef _WIN32`,
        // so it compiles to an empty module on macOS. It lives in its own target
        // directory so the Swift executable target is not "mixed language".
        .target(
            name: "Win32Bridge",
            path: "Sources/Win32Bridge",
            publicHeadersPath: "include",
            cSettings: [
                .define("UNICODE", .when(platforms: [.windows])),
                .define("_UNICODE", .when(platforms: [.windows]))
            ],
            linkerSettings: [
                .linkedLibrary("user32", .when(platforms: [.windows])),
                .linkedLibrary("shell32", .when(platforms: [.windows])),
                .linkedLibrary("ole32", .when(platforms: [.windows]))
            ]
        ),
        // Main executable target
        .executableTarget(
            name: "JacqueCopy",
            dependencies: macTargetDependencies + [
                .target(name: "Win32Bridge")
            ],
            path: "Sources/JacqueCopy",
            // Info.plist / entitlements are consumed by the app-bundling step in
            // CI, not by SwiftPM. Excluding them avoids the "Info.plist is not
            // supported as a top-level resource" build error.
            exclude: ["Resources"],
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
