# Make a Swift package from the generated API. The generated JSON data go
# into the test target as a resource, so that tests can compare both.
mkdir -p SalesReport/Sources/SalesReport SalesReport/Tests/SalesReportTests
cp generated/swift/SalesReportAPI.swift SalesReport/Sources/SalesReport/
cp generated/json/sales-report.json SalesReport/Tests/SalesReportTests/

cat > SalesReport/Package.swift <<'SWIFT'
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SalesReport",
    products: [
        .library(name: "SalesReport", targets: ["SalesReport"])
    ],
    targets: [
        .target(name: "SalesReport"),
        .testTarget(
            name: "SalesReportTests",
            dependencies: ["SalesReport"],
            resources: [.copy("sales-report.json")]
        ),
    ]
)
SWIFT

# Compile the generated code.
swift build --package-path SalesReport

# Output:
# Build complete!
