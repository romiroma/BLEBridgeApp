// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BLEBridge",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9)],
    products: [
        .library(
            name: "BLEBridge",
            targets: ["BLEBridge", "BLEBridgeLive", "BLEBridgeUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", exact: "0.54.1")
    ],
    targets: [
        .target(
            name: "BLEBridge",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .targetItem(name: "Central", condition: .none),
                .targetItem(name: "BLEPublish", condition: .none)
            ]),
        .target(
            name: "Central",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]),
        .target(
            name: "BLEPublish",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .targetItem(name: "Central", condition: .none),
                .targetItem(name: "NetworkPublisher", condition: .none)
            ]),
        .target(
            name: "NetworkPublisher",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]),
        .target(
            name: "BLEBridgeLive",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .targetItem(name: "Central", condition: .none),
                .targetItem(name: "BLEBridge", condition: .none)
            ]),
        .target(
            name: "BLEBridgeUI",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .targetItem(name: "Central", condition: .none),
                .targetItem(name: "NetworkPublisher", condition: .none),
                .targetItem(name: "BLEPublish", condition: .none),
                .targetItem(name: "BLEBridge", condition: .none)
            ],
            resources: [
                .process("Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "BLEBridgeTests",
            dependencies: ["BLEBridge"]),
    ]
)
