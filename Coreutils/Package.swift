// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Coreutils",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "ls", targets: ["ls"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-system", from: "1.2.0"),
        .package(path: "../libark")
    ],
    targets: [
        .executableTarget(
            name: "ls",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SystemPackage", package: "swift-system"),
                "libark"
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-bare-slash-regex"])
            ]
        ),
        .testTarget(
            name: "lsTests",
            dependencies: ["ls"]
        ),
    ]
)
