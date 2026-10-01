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
}

extension EMFJavaParityTests {
    /// The project directory of the reference library example in the generated output.
    static let generatedProject = "org.eclipse.emf.examples.library"

    /// Removes white space, which the reference files have reformatted by hand.
    static func withoutWhitespace(_ text: String) -> String {
        text.components(separatedBy: .whitespacesAndNewlines).joined()
    }

    /// The value of a manifest header with continuation lines joined, or `nil` if the header is missing.
    static func manifestValue(_ name: String, in text: String) -> String? {
        let lines = normalisingLineEndings(text).components(separatedBy: "\n")
        guard let start = lines.firstIndex(where: { $0.hasPrefix(name + ": ") }) else { return nil }
        var value = String(lines[start].dropFirst(name.count + 2))
        for line in lines[(start + 1)...] {
            guard line.hasPrefix(" ") else { break }
            value += line.dropFirst()
        }
        return value
    }

    /// The elements of a manifest list header without their version constraints.
    static func manifestList(_ name: String, in text: String) -> [String] {
        guard let value = manifestValue(name, in: text) else { return [] }
        return value.replacingOccurrences(of: #";version="[^"]*""#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #";bundle-version="[^"]*""#, with: "", options: .regularExpression)
            .components(separatedBy: ",")
    }

    @Test(
        "Project files of the extended library example match the Eclipse output where it was not edited by hand",
        .enabled(
            if: EMFParityTests.referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity")
    )
    @MainActor
    func projectFilesMatchReference() async throws {
        let root = try #require(EMFParityTests.referenceRoot)
        let directory = root.appendingPathComponent(Self.libraryDirectory)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-java-parity")
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }
        _ = try await GenerationPipeline.generate(
            genModelURL: directory.appendingPathComponent(Self.genModelPath), language: "java",
            outputDirectory: output, options: GenerationOptions(includeSourceRoot: true))
        func read(_ base: URL, _ path: String) throws -> String {
            try String(contentsOf: base.appendingPathComponent(path), encoding: .utf8)
        }
        let project = output.appendingPathComponent(Self.generatedProject)

        // The reference descriptor points to the generator model file, which a headless run cannot know,
        // and has an empty header comment removed.
        let descriptor = Self.withoutWhitespace(try read(project, "plugin.xml"))
            .replacingOccurrences(of: "<!---->", with: "")
        let referenceDescriptor = Self.withoutWhitespace(try read(directory, "plugin.xml"))
            .replacingOccurrences(of: #"genModel="model/extlibrary.genmodel""#, with: "")
        #expect(descriptor == referenceDescriptor)

        // The reference manifest has hand-edited versions, class path and bundle order.
        let manifest = try read(project, "META-INF/MANIFEST.MF")
        let referenceManifest = try read(directory, "META-INF/MANIFEST.MF")
        for header in [
            "Bundle-Name", "Bundle-SymbolicName", "Bundle-Vendor", "Bundle-Localization",
            "Bundle-RequiredExecutionEnvironment", "Bundle-ActivationPolicy", "Automatic-Module-Name",
        ] {
            #expect(Self.manifestValue(header, in: manifest) == Self.manifestValue(header, in: referenceManifest), "\(header)")
        }
        #expect(
            Self.manifestList("Export-Package", in: manifest)
                == Self.manifestList("Export-Package", in: referenceManifest))
        #expect(
            Self.manifestList("Require-Bundle", in: manifest).filter { $0 != "org.eclipse.core.runtime" }
                .map { $0.replacingOccurrences(of: ";visibility:=reexport", with: "") }
                == Self.manifestList("Require-Bundle", in: referenceManifest)
                .map { $0.replacingOccurrences(of: ";visibility:=reexport", with: "") })

        // The reference build properties and plugin properties were edited by hand.
        let build = Self.withoutWhitespace(try read(project, "build.properties"))
        for entry in ["model/,\\", "META-INF/,\\", "plugin.xml,\\", "plugin.properties"] {
            #expect(build.contains(entry), "build.properties lacks \(entry)")
        }
        let properties = try read(project, "plugin.properties")
        #expect(properties.contains("_UI_EXTLibrary_content_type = "))
        #expect(try read(directory, "plugin.properties").contains("_UI_EXTLibrary_content_type = "))
    }
}
