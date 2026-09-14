// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "Terminal",
    products: [
        .library(name: "Terminal", type: .static, targets: ["Terminal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        
    ],
    targets: [
        .target(
            name: "Terminal",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "Collections", package: "swift-collections")

            ],
            path: "Sources/Terminal"
        )
    ]
)
