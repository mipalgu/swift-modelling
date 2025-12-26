// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-modelling",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(
            name: "swift-ecore",
            targets: ["swift-ecore"]
        ),
        .executable(
            name: "swift-atl",
            targets: ["swift-atl"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.2"),
        .package(url: "https://github.com/mipalgu/swift-ecore.git", branch: "main"),
        .package(url: "https://github.com/mipalgu/swift-atl.git", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-subprocess", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "swift-ecore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ECore", package: "swift-ecore"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "swift-atl",
            dependencies: [
                .product(name: "ATL", package: "swift-atl"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "swift-ecore-tests",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "ECore", package: "swift-ecore"),
                "swift-ecore",
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "swift-atl-tests",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess"),
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
    ]
)
