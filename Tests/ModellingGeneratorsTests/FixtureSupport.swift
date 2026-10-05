import Foundation

/// Errors raised while locating or preparing test fixtures.
enum FixtureError: Error, CustomStringConvertible {
    case missing(String)

    var description: String {
        switch self {
        case .missing(let path): return "Test fixture not found: \(path)"
        }
    }
}

/// A scratch copy of one fixture project, removed when the value goes out of scope.
struct FixtureProject {
    /// The root directory of the copy, named after the fixture so that it is the model project.
    let root: URL

    /// The `model` folder of the copy.
    var modelDirectory: URL { root.appendingPathComponent("model") }

    /// The location of a file in the `model` folder.
    ///
    /// - Parameter name: The file name.
    /// - Returns: The location of the file in the copy.
    func model(_ name: String) -> URL { modelDirectory.appendingPathComponent(name) }

    /// The location of the committed expectation for a file.
    ///
    /// - Parameter name: The file name of the expectation.
    /// - Returns: The location in the bundled fixtures.
    func expectation(_ name: String) throws -> URL {
        try Fixtures.url(of: "\(root.lastPathComponent)/expected/\(name)")
    }

    /// Copies a bundled fixture project into a new scratch directory.
    ///
    /// - Parameter name: The name of the fixture directory.
    /// - Returns: The copy, whose directory is named `name`.
    static func make(_ name: String) throws -> FixtureProject {
        let source = try Fixtures.url(of: name)
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-genmodel-tests")
            .appendingPathComponent(UUID().uuidString)
        let root = scratch.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: source, to: root)
        for expectation in ["expected", "expected-java"] {
            try? FileManager.default.removeItem(at: root.appendingPathComponent(expectation))
        }
        return FixtureProject(root: root)
    }

    /// The location of the committed Java expectation for a file.
    ///
    /// - Parameter path: The path of the expected file relative to the generated source root.
    /// - Returns: The location in the bundled fixtures.
    func javaExpectation(_ path: String) throws -> URL {
        try Fixtures.url(of: "\(root.lastPathComponent)/expected-java/\(path)")
    }

    /// Removes the scratch copy.
    func remove() {
        try? FileManager.default.removeItem(at: root.deletingLastPathComponent())
    }
}

/// Access to the fixtures bundled with the tests.
enum Fixtures {
    /// The location of a bundled fixture.
    ///
    /// Depending on the toolchain, the copied `Resources` folder is either the
    /// bundle's resource directory itself or nested inside it, so both are tried.
    ///
    /// - Parameter path: The path relative to the `Resources` folder.
    /// - Returns: The location of the file or directory.
    /// - Throws: ``FixtureError/missing(_:)`` if it does not exist.
    static func url(of path: String) throws -> URL {
        guard let base = Bundle.module.resourceURL else { throw FixtureError.missing(path) }
        let candidates = [
            base.appendingPathComponent("Resources").appendingPathComponent(path),
            base.appendingPathComponent(path),
        ]
        guard let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            throw FixtureError.missing(path)
        }
        return url
    }
}
