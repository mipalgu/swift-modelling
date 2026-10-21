import Foundation
import Testing

/// Tests for `swift-atl transform --reference-style`, which chooses how a target model spells
/// references into its own document.
@Suite("swift-atl - reference style of target models")
struct ReferenceStyleTests {
    /// The long name of the option.
    private static let option = "--reference-style"

    /// A metamodel of linked entries whose `peer` reference is not a containment.
    static let links = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="links"
            nsURI="http://www.example.org/links" nsPrefix="links">
          <eClassifiers xsi:type="ecore:EClass" name="Link">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EReference" name="peer" eType="#//Link"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A transformation that creates one link for each task, referring to itself.
    static let transformation = """
        -- @path Tasks=/Tasks.ecore
        -- @path Links=/Links.ecore

        module TaskLinks;
        create OUT : Links from IN : Tasks;

        rule TaskLink {
            from t : Tasks!Task
            to l : Links!Link (
                name <- t.name,
                peer <- t
            )
        }
        """

    /// Runs the link transformation on the tasks fixture with extra arguments.
    ///
    /// - Parameter extra: The arguments after the source and target models.
    /// - Returns: The result of the command and the text of the target model, if any.
    @MainActor
    private func transform(_ extra: [String]) async throws -> (result: SubprocessResult, text: String?) {
        let scratch = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(scratch) }
        let atl = scratch.appendingPathComponent("TaskLinks.atl")
        let source = scratch.appendingPathComponent("tasks.xmi")
        let target = scratch.appendingPathComponent("links.xmi")
        try UnsetFeatureTests.tasks.write(
            to: scratch.appendingPathComponent("Tasks.ecore"), atomically: true, encoding: .utf8)
        try Self.links.write(
            to: scratch.appendingPathComponent("Links.ecore"), atomically: true, encoding: .utf8)
        try UnsetFeatureTests.model.write(to: source, atomically: true, encoding: .utf8)
        try Self.transformation.write(to: atl, atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--metamodel-path", scratch.path, "--source", "IN=\(source.path)",
                "--target", "OUT=\(target.path)",
            ] + extra)
        return (result, try? String(contentsOf: target, encoding: .utf8))
    }

    @Test("writes same-document references of a target without a leading # with plain")
    @MainActor
    func plainReferences() async throws {
        let (result, text) = try await transform([Self.option, "plain"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let output = try #require(text)
        #expect(output.contains("peer=\"/0\""), "\(output)")
        #expect(output.contains("peer=\"/1\""), "\(output)")
        #expect(!output.contains("#/"), "\(output)")
    }

    @Test("writes same-document references of a target with a leading # by default")
    @MainActor
    func encodedByDefault() async throws {
        let (result, text) = try await transform([])
        let (encoded, encodedText) = try await transform([Self.option, "encoded"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(encoded.succeeded, "\(encoded.stdout)\(encoded.stderr)")
        let output = try #require(text)
        #expect(output.contains("#/0"), "\(output)")
        #expect(!output.contains("peer=\"/0\""), "\(output)")
        #expect(encodedText == text)
    }

    @Test("rejects a value that is not a reference style")
    @MainActor
    func rejectsUnknownStyle() async throws {
        let (result, text) = try await transform([Self.option, "fancy"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("fancy"), "\(result.stderr)")
        #expect(text == nil)
    }

    @Test("lists the option and its values in the help of transform")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftATL(command: "transform", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("encoded"))
        #expect(result.stdout.contains("plain"))
        #expect(result.stdout.contains("Eclipse"))
    }
}
