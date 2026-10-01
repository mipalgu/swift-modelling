import Foundation
import Testing

@Suite("swift-atl transform - parameters and built-in metamodels")
struct TransformParameterTests {
    /// A transformation from Ecore to the generator metamodel that takes two parameters.
    private static let transformation = """
        -- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
        -- @nsURI GenModel=http://www.eclipse.org/emf/2002/GenModel
        -- @param modelName : String
        -- @param complianceLevel : String = '17.0'
        -- @param reflection : Boolean = false
        module Tiny;
        create OUT : GenModel from IN : Ecore;

        entrypoint rule Root() {
            to m : GenModel!GenModel (
                modelName <- thisModule.modelName,
                complianceLevel <- thisModule.complianceLevel,
                operationReflection <- thisModule.reflection,
                genPackages <- Ecore!EPackage.allInstances()->collect(p | thisModule.Pkg(p))
            )
        }

        unique lazy rule Pkg {
            from p : Ecore!EPackage
            to g : GenModel!GenPackage (
                prefix <- p.name,
                ecorePackage <- p
            )
        }
        """

    /// Writes the transformation and copies the library model next to it.
    private func project() throws -> (fixture: LibraryFixture, atl: URL, output: URL) {
        let fixture = try LibraryFixture.make()
        let atl = fixture.scratch.appendingPathComponent("Tiny.atl")
        try Self.transformation.write(to: atl, atomically: true, encoding: .utf8)
        return (fixture, atl, fixture.project.appendingPathComponent("model/tiny.genmodel"))
    }

    @Test("binds --param values to the module parameters and resolves built-in metamodels")
    @MainActor
    func bindsParameters() async throws {
        let (fixture, atl, output) = try project()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", "IN=\(fixture.ecore.path)", "--target", "OUT=\(output.path)",
                "--param", "modelName=Catalogue", "--param", "complianceLevel=11.0",
                "--param", "reflection=true",
            ])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let text = try String(contentsOf: output, encoding: .utf8)
        #expect(text.contains("modelName=\"Catalogue\""))
        #expect(text.contains("complianceLevel=\"11.0\""))
        #expect(text.contains("operationReflection=\"true\"") || !text.contains("operationReflection=\"false\""))
    }

    @Test("writes references to the source model as uri#fragment attributes")
    @MainActor
    func writesCrossDocumentReferences() async throws {
        let (fixture, atl, output) = try project()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", "IN=\(fixture.ecore.path)", "--target", "OUT=\(output.path)",
                "--param", "modelName=Catalogue",
            ])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let text = try String(contentsOf: output, encoding: .utf8)
        #expect(text.contains("ecorePackage=\"library.ecore#/\""), "\(text)")
        #expect(text.contains("<genmodel:GenModel"))
    }

    @Test("uses the declared defaults for parameters that are not given")
    @MainActor
    func usesDefaults() async throws {
        let (fixture, atl, output) = try project()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", "IN=\(fixture.ecore.path)", "--target", "OUT=\(output.path)",
                "--param", "modelName=Catalogue",
            ])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(try String(contentsOf: output, encoding: .utf8).contains("complianceLevel=\"17.0\""))
    }

    @Test("fails when a required parameter is missing")
    @MainActor
    func missingParameter() async throws {
        let (fixture, atl, output) = try project()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [atl.path, "--source", "IN=\(fixture.ecore.path)", "--target", "OUT=\(output.path)"])

        #expect(!result.succeeded)
        #expect(result.stdout.contains("modelName"))
    }

    @Test("rejects undeclared parameters, malformed arguments and values of the wrong type")
    @MainActor
    func rejectsBadParameters() async throws {
        let (fixture, atl, output) = try project()
        defer { fixture.remove() }
        let base = [atl.path, "--source", "IN=\(fixture.ecore.path)", "--target", "OUT=\(output.path)"]

        let undeclared = try await executeSwiftATL(
            command: "transform", arguments: base + ["--param", "modelName=A", "--param", "unknown=1"])
        let malformed = try await executeSwiftATL(
            command: "transform", arguments: base + ["--param", "modelName"])
        let nameless = try await executeSwiftATL(
            command: "transform", arguments: base + ["--param", "=value"])
        let wrongType = try await executeSwiftATL(
            command: "transform",
            arguments: base + ["--param", "modelName=A", "--param", "reflection=maybe"])

        #expect(!undeclared.succeeded)
        #expect(undeclared.stdout.contains("unknown"))
        #expect(!malformed.succeeded)
        #expect(malformed.stdout.contains("expected name=value"))
        #expect(!nameless.succeeded)
        #expect(nameless.stdout.contains("expected name=value"))
        #expect(!wrongType.succeeded)
        #expect(wrongType.stdout.contains("reflection") || wrongType.stdout.contains("maybe"))
    }

    @Test("lists the option in the help")
    @MainActor
    func helpMentionsParam() async throws {
        let result = try await executeSwiftATL(command: "transform", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("--param"))
        #expect(result.stdout.contains("-- @nsURI"))
    }
}
