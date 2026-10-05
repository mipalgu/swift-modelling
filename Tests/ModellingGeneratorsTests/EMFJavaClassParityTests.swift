import Foundation
import Testing

@testable import ModellingGenerators

/// Compares the generated interfaces and implementation classes with the sources of the reference library example.
///
/// The comparison runs only when the environment variable `EMF_REFERENCE_ROOT` names a checkout of
/// the reference repository; otherwise the tests are reported as skipped. The committed sources of the
/// reference example were edited after generation, so the comparison states which differences it
/// accepts and why, in `ReferenceDifferences`.
@Suite("Parity of generated classes with the Eclipse reference output", .serialized)
struct EMFJavaClassParityTests {
    /// The package of the reference example, as a directory below its source root.
    static let packageDirectory = "org/eclipse/emf/examples/extlibrary"

    /// The names of the classes of the reference example that have an interface.
    static let interfaceNames = [
        "Addressable", "AudioVisualItem", "Book", "BookOnTape", "Borrower", "CirculatingItem", "Employee", "Item",
        "Lendable", "Library", "Periodical", "Person", "VideoCassette", "Writer",
    ]

    /// The names of the classes of the reference example that have an implementation class.
    static let implementationNames = [
        "AudioVisualItem", "Book", "BookOnTape", "Borrower", "CirculatingItem", "Employee", "Item", "Library",
        "Periodical", "Person", "VideoCassette", "Writer",
    ]

    /// The differences between the committed reference sources and the generator output that the comparison accepts.
    enum ReferenceDifferences {
        /// A comment line that the reference sources carry only after a manual edit.
        static let editedComment = "  // No additional features"

        /// A misspelling in the model name of the reference sources, which the generator model spells correctly.
        static let misspelling = ("Audo Visual", "Audio Visual")

        /// The marker of members that the authors of the reference sources replaced by hand.
        static let handWritten = "@generated NOT"

        /// Files whose imports were rearranged or extended by hand in the reference sources.
        static let editedImports: Set<String> = [
            "impl/CirculatingItemImpl.java", "impl/LibraryImpl.java", "impl/PersonImpl.java",
            "impl/WriterImpl.java",
        ]
    }

    /// The generated files, written once.
    @MainActor
    static var generatedDirectory: URL?

    /// Removes the text that precedes the package statement and normalises what the comparison ignores.
    ///
    /// The string markers, the blank lines before the first documentation comment, the manually edited
    /// comment and the misspelling are removed or corrected, as listed in ``ReferenceDifferences``.
    ///
    /// - Parameters:
    ///   - text: The text of a Java file.
    ///   - isReference: Whether the text comes from the reference sources.
    /// - Returns: The lines to compare.
    static func lines(of text: String, isReference: Bool) -> [String] {
        var result: [String] = []
        var seenPackage = false
        var seenComment = false
        for line in EMFJavaParityTests.normalisingLineEndings(text).components(separatedBy: "\n") {
            if !seenPackage {
                if line.hasPrefix("package ") { seenPackage = true } else { continue }
            }
            if line.hasPrefix("/**") { seenComment = true }
            if !seenComment && line.isEmpty { continue }
            var kept = line.replacingOccurrences(
                of: EMFJavaParityTests.nonNLSPattern, with: "", options: .regularExpression)
            if isReference {
                if kept == ReferenceDifferences.editedComment { continue }
                kept = kept.replacingOccurrences(
                    of: ReferenceDifferences.misspelling.0, with: ReferenceDifferences.misspelling.1)
            }
            result.append(kept)
        }
        return result
    }

    /// Splits the lines of a class into its members: the text from each member comment to the next.
    ///
    /// - Parameter lines: The lines of a Java file.
    /// - Returns: The members keyed by their declaration line, in order, and the text before the first member.
    static func members(of lines: [String]) -> (head: [String], members: [(key: String, lines: [String])]) {
        var head: [String] = []
        var members: [(key: String, lines: [String])] = []
        var current: [String] = []
        var started = false
        for line in lines {
            if line == "  /**" {
                if started { members.append((key(of: current), current)) }
                current = [line]
                started = true
            } else if started {
                current.append(line)
            } else {
                head.append(line)
            }
        }
        if started { members.append((key(of: current), current)) }
        return (head, members)
    }

    /// The declaration line of a member: the first line after its comment that is not an annotation.
    static func key(of member: [String]) -> String {
        var afterComment = false
        for line in member {
            if line == "   */" { afterComment = true; continue }
            if afterComment, !line.trimmingCharacters(in: .whitespaces).hasPrefix("@") { return line }
        }
        return member.first ?? ""
    }

    /// Generates the reference model once and returns the output directory.
    @MainActor
    static func generate() async throws -> URL {
        if let existing = generatedDirectory { return existing }
        let root = try #require(EMFParityTests.referenceRoot)
        let genModel = root.appendingPathComponent(EMFJavaParityTests.libraryDirectory)
            .appendingPathComponent(EMFJavaParityTests.genModelPath)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-java-class-parity")
            .appendingPathComponent(UUID().uuidString)
        _ = try await GenerationPipeline.generate(
            genModelURL: genModel, language: "java", outputDirectory: output,
            options: EMFParityTests.repositoryOptions)
        generatedDirectory = output
        return output
    }

    /// Compares one generated file with its reference.
    @MainActor
    static func compare(_ relativePath: String) async throws {
        let root = try #require(EMFParityTests.referenceRoot)
        let output = try await generate()
        let reference = root.appendingPathComponent(EMFJavaParityTests.libraryDirectory)
            .appendingPathComponent("src").appendingPathComponent(packageDirectory)
            .appendingPathComponent(relativePath)
        let generated = output.appendingPathComponent(packageDirectory).appendingPathComponent(relativePath)
        let expected = lines(of: try String(contentsOf: reference, encoding: .utf8), isReference: true)
        let actual = lines(of: try String(contentsOf: generated, encoding: .utf8), isReference: false)
        guard expected.contains(where: { $0.contains(ReferenceDifferences.handWritten) })
            || ReferenceDifferences.editedImports.contains(relativePath)
        else {
            #expect(actual == expected, "\(relativePath) differs from the reference")
            return
        }

        let (expectedHead, expectedMembers) = members(of: expected)
        let (actualHead, actualMembers) = members(of: actual)
        let handWritten = Set(
            expectedMembers.filter { $0.lines.contains { $0.contains(ReferenceDifferences.handWritten) } }
                .map(\.key))
        if !ReferenceDifferences.editedImports.contains(relativePath) {
            #expect(actualHead == expectedHead, "\(relativePath) differs in its head")
        } else {
            let classLine: ([String]) -> String? = { $0.first { $0.hasPrefix("public ") } }
            #expect(classLine(actualHead) == classLine(expectedHead), "\(relativePath) differs in its declaration")
        }
        let remainingExpected = expectedMembers.filter { !handWritten.contains($0.key) }
        let remainingActual = actualMembers.filter { !handWritten.contains($0.key) }
        #expect(
            remainingActual.map(\.lines) == remainingExpected.map(\.lines),
            "\(relativePath) differs outside the members that were written by hand")
    }

    @Test(
        "Generated interfaces match the reference sources",
        .enabled(
            if: EMFParityTests.referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity"),
        arguments: interfaceNames
    )
    @MainActor
    func interfaces(_ name: String) async throws {
        try await Self.compare("\(name).java")
    }

    @Test(
        "Generated implementation classes match the reference sources",
        .enabled(
            if: EMFParityTests.referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity"),
        arguments: implementationNames
    )
    @MainActor
    func implementations(_ name: String) async throws {
        try await Self.compare("impl/\(name)Impl.java")
    }
}
