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

    /// The directory of the reference library example, relative to the reference checkout.
    static let libraryDirectory =
        "tests/org.eclipse.emf.test.tools/data/ant.expected/models/5.0/creation/library.ecore/emf"

    /// The attribute that the Eclipse tooling writes for an unsettable setting at its default value.
    ///
    /// The setting `createChild` is derived from `children` and `changeable` whenever it is
    /// not written, so a model without it means the same; the serialiser omits it because
    /// the value equals the attribute's default.
    static let derivedCreateChild = #"createChild="false""#

    /// Splits a generator model into tokens that do not depend on layout.
    ///
    /// The values of `modelDirectory` and of `foreignModel` are replaced by fixed markers
    /// and all whitespace, including attribute line wrapping, is collapsed.
    ///
    /// - Parameter text: The text of a generator model.
    /// - Returns: The whitespace-separated tokens of the normalised text.
    static func tokens(of text: String) -> [String] {
        let marker = #"modelDirectory="<normalised>""#
        let normalised = text.replacingOccurrences(
            of: #"modelDirectory="[^"]*""#, with: marker, options: .regularExpression
        ).replacingOccurrences(
            of: #"<foreignModel>[^<]*</foreignModel>"#, with: "<foreignModel>normalised</foreignModel>",
            options: .regularExpression)
        return normalised.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    @Test(
        "Library example matches the Eclipse importer output",
        .enabled(if: referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity")
    )
    @MainActor
    func libraryMatchesReference() async throws {
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
        options.operationReflection = false
        options.rootExtendsClass = "org.eclipse.emf.ecore.impl.EObjectImpl"
        options.importOrganizing = false
        options.output = outputDirectory.appendingPathComponent("library.genmodel")
        let result = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [ecore], options: options)

        let actual = try String(contentsOf: result.url, encoding: .utf8)
        let expectedTokens = Self.tokens(of: expected).filter { $0 != Self.derivedCreateChild }
        let actualTokens = Self.tokens(of: actual)
        let differences = zip(expectedTokens, actualTokens).enumerated()
            .filter { $0.element.0 != $0.element.1 }
            .map { "token \($0.offset): expected \($0.element.0) but found \($0.element.1)" }
        #expect(
            expectedTokens == actualTokens,
            """
            \(differences.joined(separator: "\n"))
            expected \(expectedTokens.count) tokens, found \(actualTokens.count)
            """)
    }
}
