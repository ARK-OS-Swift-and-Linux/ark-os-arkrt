// Copyright 2026 Aarav Ravindra Kharade
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
