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
        .library(
            name: "ModellingPipeline",
            targets: ["ModellingPipeline"]
        ),
        .library(
            name: "ModellingCommandLine",
            targets: ["ModellingCommandLine"]
        ),
        .library(
            name: "ModelTyping",
            targets: ["ModelTyping"]
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
        .executable(
            name: "swift-aql",
            targets: ["swift-aql"]
        ),
        .executable(
            name: "swift-henshin",
            targets: ["swift-henshin"]
        ),
        .executable(
            name: "swift-epsilon",
            targets: ["swift-epsilon"]
        ),
        .executable(
            name: "swift-xtend",
            targets: ["swift-xtend"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.2"),
        .package(url: "https://github.com/swiftlang/swift-subprocess", .upToNextMinor(from: "0.5.0")),
        .package(url: "https://github.com/mipalgu/swift-ecore", exact: "0.8.0"),
        .package(url: "https://github.com/mipalgu/swift-atl", exact: "0.8.0"),
        .package(url: "https://github.com/mipalgu/swift-mtl", exact: "0.8.0"),
        .package(url: "https://github.com/mipalgu/swift-aql", exact: "0.8.0"),
        .package(url: "https://github.com/mipalgu/swift-henshin", exact: "0.8.0"),
        .package(url: "https://github.com/mipalgu/swift-epsilon", exact: "0.8.0"),
        .package(url: "https://github.com/mipalgu/swift-xtend", exact: "0.8.0"),
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
            name: "ModellingPipeline",
            dependencies: [
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "ATL", package: "swift-atl"),
                .product(name: "MTL", package: "swift-mtl"),
                "ModellingGenerators",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "ModelTyping",
            dependencies: [
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "AQL", package: "swift-aql"),
                .product(name: "MTL", package: "swift-mtl"),
                .product(name: "ATL", package: "swift-atl"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "ModellingCommandLine",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "MultiLevel", package: "swift-ecore"),
                .product(name: "AQL", package: "swift-aql"),
                .product(name: "AQLMultiLevel", package: "swift-aql"),
                .product(name: "MTL", package: "swift-mtl"),
                .product(name: "ATL", package: "swift-atl"),
                "ModellingGenerators",
                "ModelTyping",
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
                .product(name: "OCL", package: "swift-ecore"),
                .product(name: "MultiLevel", package: "swift-ecore"),
                .product(name: "AQL", package: "swift-aql"),
                .product(name: "AQLMultiLevel", package: "swift-aql"),
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
                "ModelTyping",
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
                .product(name: "MultiLevel", package: "swift-ecore"),
                .product(name: "AQL", package: "swift-aql"),
                .product(name: "AQLMultiLevel", package: "swift-aql"),
                "ModellingGenerators",
                "ModellingPipeline",
                "ModellingCommandLine",
                "ModelTyping",
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "swift-aql",
            dependencies: [
                .product(name: "AQL", package: "swift-aql"),
                .product(name: "AQLMultiLevel", package: "swift-aql"),
                .product(name: "MultiLevel", package: "swift-ecore"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                "ModellingCommandLine",
                "ModelTyping",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "swift-henshin",
            dependencies: [
                .product(name: "Henshin", package: "swift-henshin"),
                .product(name: "HenshinAnalysis", package: "swift-henshin"),
                .product(name: "HenshinStateSpace", package: "swift-henshin"),
                .product(name: "AQL", package: "swift-aql"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                "ModellingCommandLine",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "swift-epsilon",
            dependencies: [
                .product(name: "EOL", package: "swift-epsilon"),
                .product(name: "EVL", package: "swift-epsilon"),
                .product(name: "ETL", package: "swift-epsilon"),
                .product(name: "EGL", package: "swift-epsilon"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                "ModellingCommandLine",
                "ModellingGenerators",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "swift-xtend",
            dependencies: [
                .product(name: "Xtend", package: "swift-xtend"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                "ModellingCommandLine",
                "ModellingGenerators",
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
            name: "ModellingPipelineTests",
            dependencies: [
                "ModellingPipeline",
                "ModellingGenerators",
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "ATL", package: "swift-atl"),
                .product(name: "MTL", package: "swift-mtl"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ModellingCommandLineTests",
            dependencies: [
                "ModellingCommandLine",
                "ModelTyping",
                .product(name: "MultiLevel", package: "swift-ecore"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "MTL", package: "swift-mtl"),
                .product(name: "ATL", package: "swift-atl"),
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
                "swift-atl",
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
                "swift-mtl",
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "swift-aql-tests",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "AQL", package: "swift-aql"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                "ModellingCommandLine",
                "swift-aql",
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ModelTypingTests",
            dependencies: [
                "ModelTyping",
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "AQL", package: "swift-aql"),
                .product(name: "MTL", package: "swift-mtl"),
                .product(name: "ATL", package: "swift-atl"),
            ],
            resources: [
                .copy("Fixtures")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "swift-henshin-tests",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "Henshin", package: "swift-henshin"),
                .product(name: "HenshinAnalysis", package: "swift-henshin"),
                .product(name: "HenshinStateSpace", package: "swift-henshin"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                "ModellingCommandLine",
                "swift-henshin",
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "swift-epsilon-tests",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EOL", package: "swift-epsilon"),
                "swift-epsilon",
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "swift-xtend-tests",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "ECore", package: "swift-ecore"),
                "swift-xtend",
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
                "swift-aql",
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
