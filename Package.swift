// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "slang",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "slang", targets: ["slang"]),
        .library(name: "SlangCore", targets: ["SlangCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "slang",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "SlangCore",
            ]
        ),
        .target(
            name: "SlangCore",
            dependencies: []
        ),
        .testTarget(
            name: "SlangCoreTests",
            dependencies: ["SlangCore"]
        ),
    ]
)
