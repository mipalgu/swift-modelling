import Foundation
import Testing

@testable import ModellingGenerators

/// Compares generator models with the reference produced by the Eclipse tooling.
///
/// The comparison runs only when the environment variable `EMF_REFERENCE_ROOT` names a
/// checkout of the reference repository; otherwise the test is reported as skipped.
@Suite("Parity with the Eclipse reference output")
struct EMFParityTests {
    /// The environment variable that names the reference checkout.
    static let referenceRootVariable = "EMF_REFERENCE_ROOT"

    /// The location of the reference checkout, if the environment names one.
    static let referenceRoot: URL? = ProcessInfo.processInfo.environment[referenceRootVariable]
        .flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0) }

    /// The generation options that match the layout of the reference sources: the code style of the
    /// repository.
    static var repositoryOptions: GenerationOptions { repositoryGeneration(includeSourceRoot: nil) }

    /// The generation options that match the layout of the reference sources.
    ///
    /// - Parameter includeSourceRoot: Whether the source directory is part of the output location.
    /// - Returns: The options, with the code style of the repository.
    static func repositoryGeneration(includeSourceRoot: Bool?) -> GenerationOptions {
        GenerationOptions(includeSourceRoot: includeSourceRoot, codeStyle: JavaCodeStyleTests.repositoryStyle)
    }

    /// The directory of the reference library example, relative to the reference checkout.
    static let libraryDirectory =
        "tests/org.eclipse.emf.test.tools/data/ant.expected/models/5.0/creation/library.ecore/emf"

    /// Splits a generator model into lines, replacing the values that legitimately differ.
    ///
    /// The layout is compared exactly, including attribute wrapping and indentation. Only two values are
    /// replaced by fixed markers, because they depend on where the model is written rather than on the
    /// generator: `modelDirectory` (the reference names a build-system placeholder, whereas the importer
    /// derives the directory from the project name) and `foreignModel` (the reference stores a path
    /// relative to a different project layout). The model name also differs only when the output file
    /// name differs, which this test avoids by writing `library.genmodel`.
    ///
    /// - Parameter text: The text of a generator model.
    /// - Returns: The lines of the normalised text.
    static func lines(of text: String) -> [String] {
        let marker = #"modelDirectory="<normalised>""#
        let normalised = text.replacingOccurrences(
            of: #"modelDirectory="[^"]*""#, with: marker, options: .regularExpression
        ).replacingOccurrences(
            of: #"<foreignModel>[^<]*</foreignModel>"#, with: "<foreignModel>normalised</foreignModel>",
            options: .regularExpression)
        return normalised.components(separatedBy: "\n")
    }

    /// Imports the reference library model and compares the result with the generator model of the reference.
    ///
    /// - Parameter configure: Sets the options that the reference needs in addition to the common ones.
    @MainActor
    func expectLibraryMatchesReference(configure: (inout GenModelImportOptions) -> Void) async throws {
        let root = try #require(Self.referenceRoot)
        let directory = root.appendingPathComponent(Self.libraryDirectory)
        let referenceEcore = directory.appendingPathComponent("library.ecore")
        let expected = try String(
            contentsOf: directory.appendingPathComponent("library.genmodel"), encoding: .utf8)

        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-genmodel-parity")
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: scratch) }
        let outputDirectory = scratch.appendingPathComponent("emf")
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let ecore = outputDirectory.appendingPathComponent("library.ecore")
        try FileManager.default.copyItem(at: referenceEcore, to: ecore)

        var options = GenModelImportOptions()
        options.basePackage = "org.examples"
        options.copyright = "This is my code."
        options.complianceLevel = "5.0"
        options.modelPluginID = "library.model"
        configure(&options)
        options.output = outputDirectory.appendingPathComponent("library.genmodel")
        let result = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [ecore], options: options)

        let actual = try String(contentsOf: result.url, encoding: .utf8)
        let expectedLines = Self.lines(of: expected)
        let actualLines = Self.lines(of: actual)
        let differences = zip(expectedLines, actualLines).enumerated()
            .filter { $0.element.0 != $0.element.1 }
            .map { "line \($0.offset + 1): expected \($0.element.0) but found \($0.element.1)" }
        #expect(
            expectedLines == actualLines,
            """
            \(differences.joined(separator: "\n"))
            expected \(expectedLines.count) lines, found \(actualLines.count)
            """)
    }

    @Test(
        "Library example matches the Eclipse importer output",
        .enabled(if: referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity")
    )
    @MainActor
    func libraryMatchesReference() async throws {
        try await expectLibraryMatchesReference { options in
            options.operationReflection = false
            options.rootExtendsClass = "org.eclipse.emf.ecore.impl.EObjectImpl"
            options.importOrganizing = false
        }
    }

    @Test(
        "Library example matches the Eclipse importer output with the headless defaults",
        .enabled(if: referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity")
    )
    @MainActor
    func libraryMatchesReferenceWithHeadlessDefaults() async throws {
        try await expectLibraryMatchesReference { _ in }
    }
}
