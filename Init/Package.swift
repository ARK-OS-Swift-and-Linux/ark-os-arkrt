// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "Init",
    dependencies: [
        .package(path: "../Kernel"),
        .package(path: "../System"),
        .package(path: "../Network"),
        .package(path: "../Service"),
        .package(path: "../Terminal"),
    ],
    targets: [
        .executableTarget(
            name: "Init",
            dependencies: [
                .product(name: "Kernel", package: "Kernel"),
                .product(name: "System", package: "System"),
                .product(name: "Connect", package: "Network"),
                .product(name: "Service", package: "Service"),
                .product(name: "Terminal", package: "Terminal"),
            ],
            linkerSettings: [
                .linkedLibrary("stdc++")
            ]
        )
    ]
)
