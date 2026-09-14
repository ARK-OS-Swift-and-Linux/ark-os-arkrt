// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "System",
    products: [
        .library(name: "System", type: .static, targets: ["System"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/sqlite.swift.git", from: "0.15.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "System",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "SQLite", package: "sqlite.swift"),
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources/System"
        )
    ]
)
