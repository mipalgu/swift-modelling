import Foundation
import Testing

/// Tests for `swift-mtl generate --unset-features`, which chooses how templates read
/// structural features that a model does not set.
@Suite("swift-mtl generate - reading unset features")
struct UnsetFeatureTests {
    /// The long name of the option.
    private static let option = "--unset-features"

    /// A metamodel whose counters have a name and an integer count without a declared default.
    private static let metamodel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="counters"
            nsURI="http://www.example.org/counters" nsPrefix="counters">
          <eClassifiers xsi:type="ecore:EClass" name="Counter">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="count"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EInt"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A counter that sets its name but leaves its count unset.
    private static let model = """
        <?xml version="1.0" encoding="UTF-8"?>
        <counters:Counter xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:counters="http://www.example.org/counters" name="visits"/>
        """

    /// A template that writes the count of a counter between brackets.
    private static let template = """
        [module Counts('http://www.example.org/counters')]

        [template main(c : Counter)]
        [file ('count.txt', 'overwrite', 'UTF-8')]
        <[c.count/]>
        [/file]
        [/template]
        """

    /// Generates the count of the counter with extra arguments.
    ///
    /// - Parameter extra: The arguments after the model and output directory.
    /// - Returns: The result of the command and the generated text, if any.
    @MainActor
    private func generate(_ extra: [String]) async throws -> (result: SubprocessResult, text: String?) {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let metamodel = scratch.appendingPathComponent("counters.ecore")
        let model = scratch.appendingPathComponent("visits.xmi")
        let template = scratch.appendingPathComponent("Counts.mtl")
        let output = scratch.appendingPathComponent("out")
        try Self.metamodel.write(to: metamodel, atomically: true, encoding: .utf8)
        try Self.model.write(to: model, atomically: true, encoding: .utf8)
        try Self.template.write(to: template, atomically: true, encoding: .utf8)

        let result = try await executeSwiftMTL(
            command: "generate",
            arguments: [
                template.path, "--metamodel", metamodel.path, "--model", model.path,
                "--output", output.path,
            ] + extra)
        let text = try? String(contentsOf: output.appendingPathComponent("count.txt"), encoding: .utf8)
        return (result, text)
    }

    @Test("reads an unset integer as zero by default, as the Eclipse Modeling Framework does")
    @MainActor
    func defaultReadsDataTypeDefault() async throws {
        let (result, text) = try await generate([])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains("<0>") == true, "\(text ?? "no output")")
    }

    @Test("reads an unset integer as zero with --unset-features defaults")
    @MainActor
    func explicitDefaults() async throws {
        let (result, text) = try await generate([Self.option, "defaults"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains("<0>") == true, "\(text ?? "no output")")
    }

    @Test("reads an unset integer as undefined with --unset-features undefined")
    @MainActor
    func undefinedReadsNothing() async throws {
        let (result, text) = try await generate([Self.option, "undefined"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text?.contains("<>") == true, "\(text ?? "no output")")
        #expect(text?.contains("<0>") == false)
    }

    @Test("rejects a value that is not a mode")
    @MainActor
    func rejectsUnknownMode() async throws {
        let (result, _) = try await generate([Self.option, "sometimes"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("sometimes"))
    }

    @Test("describes the option and its values in the help")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftMTL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("defaults"))
        #expect(result.stdout.contains("undefined"))
        #expect(result.stdout.contains("Eclipse Modeling Framework"))
    }
}
