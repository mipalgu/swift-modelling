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
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.2"),
        .package(url: "https://github.com/mipalgu/swift-ecore.git", branch: "main"),
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
    ]
)
