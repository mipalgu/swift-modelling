import Foundation
import Testing

@testable import ModellingGenerators

/// Compares the imports of generated Java with a reference model whose generator model organises its imports.
///
/// The comparison runs only when the environment variable `EMF_REFERENCE_ROOT` names a checkout of
/// the reference repository; otherwise the test is reported as skipped.
@Suite("Parity of organised imports with the Eclipse reference output")
struct EMFJavaImportParityTests {
    /// The directory of the reference model, relative to the reference checkout.
    static let modelDirectory = "tests/org.eclipse.emf.test.core/src/org/eclipse/emf/test/core/xrefsmodel"

    /// The generator model of the reference model, relative to its directory.
    static let genModelPath = "xrefsmodel.genmodel"

    /// The directory that holds the generated files, relative to the generated source root.
    static let generatedDirectory = "org/eclipse/emf/test/core/xrefsmodel"

    /// The generated files without hand edits that the comparison covers, relative to the reference directory.
    static let paths = [
        "XRefsModelFactory.java", "XRefsModelPackage.java", "impl/XRefsModelFactoryImpl.java",
        "util/XRefsModelSwitch.java", "util/XRefsModelAdapterFactory.java",
    ]

    /// The text of a file without its opening comment, blank lines, trailing spaces and override annotations.
    ///
    /// The reference sources were formatted by the Eclipse tools and written by an older release of the
    /// generator, so the spacing, the copyright comment and the annotations are left out of the comparison.
    ///
    /// - Parameter text: The text of a Java file.
    /// - Returns: The significant lines.
    static func significantLines(_ text: String) -> [String] {
        let unified = EMFJavaParityTests.normalisingLineEndings(text)
        let body = unified.range(of: "*/\n").map { String(unified[$0.upperBound...]) } ?? unified
        return body.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.replacingOccurrences(of: #"\s+$"#, with: "", options: .regularExpression) }
            .filter { !$0.isEmpty && $0.trimmingCharacters(in: .whitespaces) != "@Override" }
    }

    /// The import block of a file, from its first to its last import statement, with its blank lines.
    ///
    /// - Parameter text: The text of a Java file.
    /// - Returns: The lines of the import block.
    static func importBlock(_ text: String) -> [String] {
        let lines = EMFJavaParityTests.normalisingLineEndings(text).components(separatedBy: "\n")
        guard let first = lines.firstIndex(where: { $0.hasPrefix("import ") }),
            let last = lines.lastIndex(where: { $0.hasPrefix("import ") })
        else { return [] }
        return Array(lines[first...last])
    }

    @Test(
        "A model that organises its imports matches the Eclipse output",
        .enabled(
            if: EMFParityTests.referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity"),
        arguments: paths
    )
    @MainActor
    func organisedImportsMatchReference(path: String) async throws {
        let root = try #require(EMFParityTests.referenceRoot)
        let directory = root.appendingPathComponent(Self.modelDirectory)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-java-import-parity")
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }

        _ = try await GenerationPipeline.generate(
            genModelURL: directory.appendingPathComponent(Self.genModelPath), language: "java",
            outputDirectory: output)

        let expected = try String(contentsOf: directory.appendingPathComponent(path), encoding: .utf8)
        let actual = try String(
            contentsOf: output.appendingPathComponent(Self.generatedDirectory).appendingPathComponent(path),
            encoding: .utf8)
        #expect(Self.importBlock(actual) == Self.importBlock(expected), "\(path) imports differ")
        #expect(
            Self.significantLines(actual) == Self.significantLines(expected),
            "\(path) differs from the reference beyond header, spacing and annotations")
    }
}
