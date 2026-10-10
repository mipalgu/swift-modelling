import Foundation

/// The library fixture that the generator tests share, copied into a scratch directory.
///
/// The fixture lives with the tests of the generator library; the copy leaves out the committed
/// expectations so that only the model remains.
struct LibraryFixture {
    /// The directory of the shared fixtures.
    static let fixtureRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources")

    /// The directory that holds the Java files that generating the library fixture must produce.
    static let expectedJava = fixtureRoot.appendingPathComponent("library/expected-java")

    /// The scratch directory that holds the copy.
    let scratch: URL

    /// The copy of the project directory.
    var project: URL { scratch.appendingPathComponent("library") }

    /// The copy of the Ecore model.
    var ecore: URL { project.appendingPathComponent("model/library.ecore") }

    /// The generator model that is written beside the Ecore model.
    var genModel: URL { project.appendingPathComponent("model/library.genmodel") }

    /// The directory that generated code is written to.
    var output: URL { scratch.appendingPathComponent("java") }

    /// Copies the fixture into a new scratch directory.
    ///
    /// - Returns: The copy.
    /// - Throws: File system errors.
    static func make() throws -> LibraryFixture {
        let scratch = try createTemporaryDirectory()
        let fixture = LibraryFixture(scratch: scratch)
        try FileManager.default.copyItem(
            at: fixtureRoot.appendingPathComponent("library"), to: fixture.project)
        for expectation in [
            "expected", "expected-java", "expected-java-project", "expected-java-variants", "expected-swift", "swift-check", "expected-c", "c-check",
            "expected-cpp", "cpp-check",
        ] {
            try? FileManager.default.removeItem(at: fixture.project.appendingPathComponent(expectation))
        }
        return fixture
    }

    /// Removes the scratch directory.
    func remove() { cleanupTemporaryDirectory(scratch) }

    /// The files below a directory, relative to it and sorted.
    ///
    /// - Parameter directory: The directory to list.
    /// - Returns: The relative paths of the regular files.
    static func files(below directory: URL) -> [String] {
        let base = directory.standardizedFileURL.path
        guard
            let enumerator = FileManager.default.enumerator(
                at: directory, includingPropertiesForKeys: [.isRegularFileKey])
        else { return [] }
        var paths: [String] = []
        for case let url as URL in enumerator {
            let isFile = (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
            if isFile { paths.append(String(url.standardizedFileURL.path.dropFirst(base.count + 1))) }
        }
        return paths.sorted()
    }
}
