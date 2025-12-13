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
    ]
)
