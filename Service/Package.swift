// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "Service",
    products: [
        .library(name: "Service", type: .static, targets: ["Service"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", exact: "1.0.4")
    ],
    targets: [
        .target(
            name: "Service",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            path: "Sources/Service"
        )
    ]
)
