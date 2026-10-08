// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-modelling",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftModelling",
            targets: ["SwiftModelling"]
        ),
        .library(
            name: "ModellingGenerators",
            targets: ["ModellingGenerators"]
        ),
        .executable(
            name: "swift-ecore",
            targets: ["swift-ecore"]
        ),
        .executable(
            name: "swift-atl",
            targets: ["swift-atl"]
        ),
        .executable(
            name: "swift-mtl",
            targets: ["swift-mtl"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.2"),
        .package(url: "https://github.com/swiftlang/swift-subprocess", .upToNextMinor(from: "0.5.0")),
        .package(url: "https://github.com/mipalgu/swift-ecore", branch: "main"),
        .package(url: "https://github.com/mipalgu/swift-atl", branch: "main"),
        .package(url: "https://github.com/mipalgu/swift-mtl", branch: "main"),
        .package(url: "https://github.com/mipalgu/swift-docc-static", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "SwiftModelling",
            dependencies: [],
            resources: [
                .copy("SwiftModelling.docc")
            ]
        ),
        .target(
            name: "ModellingGenerators",
            dependencies: [
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "GenModel", package: "swift-ecore"),
                .product(name: "ATL", package: "swift-atl"),
                .product(name: "MTL", package: "swift-mtl"),
            ],
            resources: [
                .copy("Transformations"),
                .copy("Templates"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "ModellingCommandLine",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ModellingGenerators",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "swift-ecore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ECore", package: "swift-ecore"),
                "ModellingGenerators",
                "ModellingCommandLine",
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
                .product(name: "GenModel", package: "swift-ecore"),
                "ModellingGenerators",
                "ModellingCommandLine",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "swift-mtl",
            dependencies: [
                .product(name: "MTL", package: "swift-mtl"),
                "ModellingGenerators",
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ModellingGeneratorsTests",
            dependencies: [
                "ModellingGenerators",
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "GenModel", package: "swift-ecore"),
            ],
            resources: [
                .copy("Resources")
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
                .product(name: "Subprocess", package: "swift-subprocess")
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "swift-mtl-tests",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "MTL", package: "swift-mtl"),
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "TutorialTests",
            dependencies: [
                "SwiftModelling",
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "ATL", package: "swift-atl"),
                .product(name: "MTL", package: "swift-mtl"),
                "swift-ecore",
                "swift-atl",
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
