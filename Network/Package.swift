// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "Network",
    products: [
        .library(name: "Connect", type: .static, targets: ["Connect"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.100.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.37.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.45.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.35.0"),
        .package(url: "https://github.com/apple/swift-nio-ssh.git", from: "0.15.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.27.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", exact: "1.0.4")
    ],
    targets: [
        .target(
            name: "Connect",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "NIOSSH", package: "swift-nio-ssh"),
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            path: "Sources/Network"
        )
    ]
)
