// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "Kernel",
    products: [
        .library(name: "Kernel", type: .static, targets: ["Kernel"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-system.git", from: "1.0.0"),
        .package(url: "https://github.com/svdo/swift-netutils.git", from: "4.2.1"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-mmio.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
     ],
    targets: [
        .target(
            name: "Kernel",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system"),
                .product(name: "NetUtils", package: "swift-netutils"),
                .product(name: "MMIO", package: "swift-mmio"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Crypto", package: "swift-crypto")
            ],
            path: "Sources/Kernel"
        )
    ]
)
