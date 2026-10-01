import Foundation
import Testing

@testable import ModellingGenerators

/// Compares generated Java with the sources of the reference library example.
///
/// The comparison runs only when the environment variable `EMF_REFERENCE_ROOT` names a checkout of
/// the reference repository; otherwise the test is reported as skipped.
@Suite("Parity of generated Java with the Eclipse reference output")
struct EMFJavaParityTests {
    /// The directory of the reference library example, relative to the reference checkout.
    static let libraryDirectory = "examples/org.eclipse.emf.examples.library"

    /// The generator model of the reference library example, relative to its directory.
    static let genModelPath = "model/extlibrary.genmodel"

    /// The generated enumeration of the reference library example, relative to its directory.
    static let bookCategoryPath = "src/org/eclipse/emf/examples/extlibrary/BookCategory.java"

    /// The location of the generated enumeration in the output.
    static let generatedBookCategory = "org/eclipse/emf/examples/extlibrary/BookCategory.java"

    /// The generated factory files of the reference library example, relative to its source directory.
    static let factoryPaths = [
        "org/eclipse/emf/examples/extlibrary/EXTLibraryFactory.java",
        "org/eclipse/emf/examples/extlibrary/impl/EXTLibraryFactoryImpl.java",
    ]

    /// A blank line between two import statements.
    static let importGapPattern = #"(import [^\n]*;\n)\n(?=import )"#

    /// The marker that asks tools not to externalise a string.
    static let nonNLSPattern = #" //\$NON-NLS-\d\$"#

    /// Removes the comment that opens a file, which carries the copyright text.
    ///
    /// - Parameter text: The text of a Java file.
    /// - Returns: The text without its opening comment.
    static func withoutHeader(_ text: String) -> String {
        guard text.hasPrefix("/**"), let end = text.range(of: "*/\n") else { return text }
        return String(text[end.upperBound...])
    }

    /// Joins the groups of an import block, whose spacing differs between generator versions.
    ///
    /// - Parameter text: The text of a Java file.
    /// - Returns: The text without blank lines between import statements.
    static func withoutImportGaps(_ text: String) -> String {
        text.replacingOccurrences(of: importGapPattern, with: "$1", options: .regularExpression)
    }

    /// Converts line endings to line feeds.
    ///
    /// - Parameter text: The text to normalise.
    /// - Returns: The text with line feeds only.
    static func normalisingLineEndings(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
    }

    @Test(
        "BookCategory of the extended library example matches the Eclipse output",
        .enabled(
            if: EMFParityTests.referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity")
    )
    @MainActor
    func bookCategoryMatchesReference() async throws {
        let root = try #require(EMFParityTests.referenceRoot)
        let directory = root.appendingPathComponent(Self.libraryDirectory)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-java-parity")
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }

        let result = try await GenerationPipeline.generate(
            genModelURL: directory.appendingPathComponent(Self.genModelPath), language: "java",
            outputDirectory: output)
        #expect(result.files.contains { $0.path.hasSuffix(Self.generatedBookCategory) })

        let expected = Self.normalisingLineEndings(
            try String(
                contentsOf: directory.appendingPathComponent(Self.bookCategoryPath), encoding: .utf8))
        let actual = Self.normalisingLineEndings(
            try String(contentsOf: output.appendingPathComponent(Self.generatedBookCategory), encoding: .utf8))

        #expect(!expected.contains("$NON-NLS"), "the committed example carries no string markers")
        let actualWithoutMarkers = actual.replacingOccurrences(
            of: Self.nonNLSPattern, with: "", options: .regularExpression)
        #expect(actual != actualWithoutMarkers, "the generator model asks for string markers")
        #expect(
            Self.withoutHeader(actualWithoutMarkers) == Self.withoutHeader(expected),
            "BookCategory.java differs from the reference beyond header and string markers")
    }

    /// The generated package interface of the reference library example, relative to its directory.
    static let packageInterfacePath = "src/org/eclipse/emf/examples/extlibrary/EXTLibraryPackage.java"

    /// The generated package implementation of the reference library example, relative to its directory.
    static let packageImplementationPath = "src/org/eclipse/emf/examples/extlibrary/impl/EXTLibraryPackageImpl.java"

    /// The documentation line that the reference interface carries from an older generator release.
    ///
    /// The reference sources were produced before the generator stopped writing the release of the content
    /// type constant, so the line is left out of the comparison.
    static let olderReleaseLine = "   * @since 2.4"

    /// Removes the lines that the reference carries from an older generator release.
    ///
    /// - Parameter text: The text of a reference file.
    /// - Returns: The text without those lines.
    static func withoutOlderReleaseLines(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .filter { $0 != olderReleaseLine }
            .joined(separator: "\n")
    }

    @Test(
        "The package interface and implementation of the extended library match the Eclipse output",
        .enabled(
            if: EMFParityTests.referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity"),
        arguments: [
            (packageInterfacePath, "org/eclipse/emf/examples/extlibrary/EXTLibraryPackage.java"),
            (packageImplementationPath, "org/eclipse/emf/examples/extlibrary/impl/EXTLibraryPackageImpl.java"),
        ]
    )
    @MainActor
    func packageFilesMatchReference(referencePath: String, generatedPath: String) async throws {
        let root = try #require(EMFParityTests.referenceRoot)
        let directory = root.appendingPathComponent(Self.libraryDirectory)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-java-parity")
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }

        _ = try await GenerationPipeline.generate(
            genModelURL: directory.appendingPathComponent(Self.genModelPath), language: "java",
            outputDirectory: output)

        let expected = Self.withoutOlderReleaseLines(
            Self.normalisingLineEndings(
                try String(
                    contentsOf: directory.appendingPathComponent(referencePath), encoding: .utf8)))
        let actual = Self.normalisingLineEndings(
            try String(contentsOf: output.appendingPathComponent(generatedPath), encoding: .utf8))
        #expect(
            Self.withoutHeader(actual) == Self.withoutHeader(expected),
            "\(generatedPath) differs from the reference beyond its header")
    }

    @Test(
        "The factory of the extended library example matches the Eclipse output",
        .enabled(
            if: EMFParityTests.referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity"),
        arguments: factoryPaths
    )
    @MainActor
    func factoryMatchesReference(_ path: String) async throws {
        let root = try #require(EMFParityTests.referenceRoot)
        let directory = root.appendingPathComponent(Self.libraryDirectory)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-java-parity")
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }

        let result = try await GenerationPipeline.generate(
            genModelURL: directory.appendingPathComponent(Self.genModelPath), language: "java",
            outputDirectory: output)
        #expect(result.files.contains { $0.path.hasSuffix(path) })

        let expected = Self.normalisingLineEndings(
            try String(
                contentsOf: directory.appendingPathComponent("src").appendingPathComponent(path),
                encoding: .utf8))
        let actual = Self.normalisingLineEndings(
            try String(contentsOf: output.appendingPathComponent(path), encoding: .utf8))
        let actualWithoutMarkers = actual.replacingOccurrences(
            of: Self.nonNLSPattern, with: "", options: .regularExpression)
        let expectedWithoutMarkers = expected.replacingOccurrences(
            of: Self.nonNLSPattern, with: "", options: .regularExpression)
        #expect(
            Self.withoutImportGaps(Self.withoutHeader(actualWithoutMarkers))
                == Self.withoutImportGaps(Self.withoutHeader(expectedWithoutMarkers)),
            "\(path) differs from the reference beyond header, string markers and import spacing")
    }
}
