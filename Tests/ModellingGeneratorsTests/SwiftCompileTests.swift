import Foundation
import Testing

@testable import ModellingGenerators

/// Compiles generated Swift against the ECore product.
///
/// Each test copies the generated files of a fixture into a package of its own that depends on a checkout of
/// the swift-ecore package, and builds it with `swift build`. A fixture that has a file `swift-check/Check.swift`
/// also gets an executable that exercises the generated model; the test runs it with `swift run`.
///
/// The tests run only when `swift` can be found on the search path and a checkout of swift-ecore can be found:
/// either the directory that `SWIFT_ECORE_PACKAGE` names, or the checkout in the scratch directory of the
/// build that runs the tests. Packages and build products are written below the scratch directory that
/// `SWIFT_COMPILE_SCRATCH` names, by default the scratch directory of the build.
@Suite("Compiling generated Swift", .serialized)
struct SwiftCompileTests {
    /// The environment variable that names the swift-ecore package.
    static let packageVariable = "SWIFT_ECORE_PACKAGE"

    /// The environment variable that names the directory for packages and build products.
    static let scratchVariable = "SWIFT_COMPILE_SCRATCH"

    /// The name of the module that holds the generated files.
    static let moduleName = "Model"

    /// The name of the executable that checks the generated model.
    static let checkName = "Check"

    /// The path of the check of a fixture, relative to the fixture.
    static let checkPath = "swift-check/Check.swift"

    /// The location of the Swift driver, if one can be found on the search path.
    static var swift: URL? {
        let search = ProcessInfo.processInfo.environment["PATH"] ?? ""
        #if os(Windows)
            let separator: Character = ";"
            let name = "swift.exe"
        #else
            let separator: Character = ":"
            let name = "swift"
        #endif
        for directory in search.split(separator: separator) {
            let candidate = URL(fileURLWithPath: String(directory)).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: candidate.path) { return candidate }
        }
        return nil
    }

    /// The swift-ecore package and the scratch directory to build in, if they can be found.
    static let environment: (package: URL, scratch: URL)? = {
        let variables = ProcessInfo.processInfo.environment
        if let path = variables[packageVariable], !path.isEmpty {
            let scratch = variables[scratchVariable].flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0) }
                ?? FileManager.default.temporaryDirectory.appendingPathComponent("swift-modelling-compile")
            return (URL(fileURLWithPath: path), scratch)
        }
        var directory = Bundle.module.bundleURL
        for _ in 0..<8 {
            directory = directory.deletingLastPathComponent()
            let package = directory.appendingPathComponent("checkouts/swift-ecore")
            if FileManager.default.fileExists(atPath: package.appendingPathComponent("Package.swift").path) {
                let scratch = variables[scratchVariable].flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0) }
                    ?? directory
                return (package, scratch)
            }
        }
        return nil
    }()

    /// Runs a program and collects its output.
    ///
    /// - Parameters:
    ///   - executable: The program to run.
    ///   - arguments: The arguments of the program.
    ///   - directory: The directory to run in.
    /// - Returns: The exit status and the text that the program wrote.
    static func run(_ executable: URL, _ arguments: [String], in directory: URL) throws -> (
        status: Int32, output: String
    ) {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    /// The manifest of the package that holds the generated files of a fixture.
    ///
    /// - Parameters:
    ///   - name: The name of the fixture.
    ///   - ecore: The location of the swift-ecore package.
    ///   - hasCheck: Whether the package has an executable that checks the model.
    /// - Returns: The text of the manifest.
    static func manifest(name: String, ecore: URL, hasCheck: Bool) -> String {
        let dependencies = """
            [.product(name: "ECore", package: "\(ecore.lastPathComponent)"), \
            .product(name: "EMFBase", package: "\(ecore.lastPathComponent)")]
            """
        let check =
            hasCheck
            ? """
                ,
                        .executableTarget(
                            name: "\(checkName)", dependencies: ["\(moduleName)"] + \(dependencies),
                            path: "Sources/\(checkName)")
                """
            : ""
        return """
            // swift-tools-version: 6.0
            import PackageDescription

            let package = Package(
                name: "Generated\(name.prefix(1).uppercased() + name.dropFirst())",
                platforms: [.macOS(.v15)],
                dependencies: [.package(path: "\(ecore.path)")],
                targets: [
                    .target(name: "\(moduleName)", dependencies: \(dependencies), path: "Sources/\(moduleName)")\(check)
                ]
            )

            """
    }

    /// Writes the package of a fixture: its manifest, the generated files, and the check if the fixture has one.
    ///
    /// - Parameters:
    ///   - golden: The fixture.
    ///   - generated: The project that holds the generated files.
    ///   - package: The directory to write the package to.
    ///   - ecore: The location of the swift-ecore package.
    /// - Returns: Whether the package has a check.
    static func writePackage(
        _ golden: SwiftGoldenCase, generated: GeneratedProject, to package: URL, ecore: URL
    ) throws -> Bool {
        let manager = FileManager.default
        try? manager.removeItem(at: package)
        let sources = package.appendingPathComponent("Sources/\(moduleName)")
        try manager.createDirectory(at: sources, withIntermediateDirectories: true)
        for path in generated.generatedPaths() {
            let target = sources.appendingPathComponent(path)
            try manager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            try manager.copyItem(at: generated.file(path), to: target)
        }
        let check = try? Fixtures.url(of: "\(golden.fixture)/\(checkPath)")
        if let check {
            let directory = package.appendingPathComponent("Sources/\(checkName)")
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            try manager.copyItem(at: check, to: directory.appendingPathComponent("Check.swift"))
        }
        try manifest(name: golden.fixture, ecore: ecore, hasCheck: check != nil).write(
            to: package.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        return check != nil
    }

    @Test(
        "Generated files compile against the ECore product and pass their checks",
        .enabled(if: swift != nil, "No swift found on the search path; skipping the compile test"),
        .enabled(if: environment != nil, "No swift-ecore checkout found; skipping the compile test"),
        arguments: SwiftGoldenCase.all
    )
    @MainActor
    func compiles(_ golden: SwiftGoldenCase) async throws {
        let swift = try #require(Self.swift)
        let environment = try #require(Self.environment)
        let generated = try await generateSwift(golden)
        defer { generated.remove() }

        let package = environment.scratch.appendingPathComponent("compile-\(golden.fixture)-package")
        let scratch = environment.scratch.appendingPathComponent("compile-\(golden.fixture)")
        let hasCheck = try Self.writePackage(
            golden, generated: generated, to: package, ecore: environment.package)
        let build = try Self.run(swift, ["build", "--scratch-path", scratch.path], in: package)
        #expect(build.status == 0, "swift build failed:\n\(build.output.suffix(4000))")
        guard build.status == 0, hasCheck else { return }

        let check = try Self.run(
            swift, ["run", "--scratch-path", scratch.path, Self.checkName], in: package)
        #expect(check.status == 0, "the check of the generated model failed:\n\(check.output.suffix(4000))")
        #expect(check.output.contains("checks passed"))
    }

    @Test("The manifest depends on the package by path and names the check only when there is one")
    func manifestText() {
        let ecore = URL(fileURLWithPath: "/work/checkouts/swift-ecore")
        let plain = Self.manifest(name: "library", ecore: ecore, hasCheck: false)
        #expect(plain.contains(#".package(path: "/work/checkouts/swift-ecore")"#))
        #expect(plain.contains(#"package: "swift-ecore""#))
        #expect(plain.contains("name: \"GeneratedLibrary\""))
        #expect(!plain.contains("executableTarget"))
        let checked = Self.manifest(name: "library", ecore: ecore, hasCheck: true)
        #expect(checked.contains(#".executableTarget("#))
        #expect(checked.contains(#"path: "Sources/Check""#))
    }
}
