import Foundation
import Testing

@testable import ModellingGenerators

/// A fixture generated with generator model settings other than the defaults.
struct JavaClassVariant: Sendable, CustomTestStringConvertible {
    /// The name of the variant, which names the directory of its expectations.
    let name: String

    /// The name of the fixture directory.
    let fixture: String

    /// The file stem of the source model.
    let stem: String

    /// The import options of the variant.
    let options: GenModelImportOptions

    /// Attributes added to the generator model element, such as `minimalReflectiveMethods="false"`.
    let attributes: String

    /// The generated files that the expectations cover, relative to the generated source root.
    let files: [String]

    var testDescription: String { name }

    /// The variants with reviewed expectations.
    static let all: [JavaClassVariant] = [
        JavaClassVariant(
            name: "plain-operations", fixture: "library", stem: "library",
            options: GenModelImportOptions(basePackage: "org.example", operationReflection: false),
            attributes: "", files: ["org/example/library/impl/LibraryImpl.java"]),
        JavaClassVariant(
            name: "all-reflective-methods", fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes"),
            attributes: #"minimalReflectiveMethods="false" switchMissingDefaultCase="true""#,
            files: ["org/example/shapes/classes/impl/CircleImpl.java"]),
        JavaClassVariant(
            name: "boolean-flags", fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes"),
            attributes: #"booleanFlagsField="eFlags" booleanFlagsReservedBits="8""#,
            files: ["org/example/shapes/classes/impl/ShapeImpl.java", "org/example/shapes/classes/impl/CircleImpl.java"]),
        JavaClassVariant(
            name: "public-constructors-without-notification", fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes"),
            attributes: #"publicConstructors="true" suppressNotification="true" nonNLSMarkers="true""#,
            files: ["org/example/shapes/classes/impl/CanvasImpl.java"]),
    ]
}

@Suite("Java classes with other generator model settings")
struct JavaClassVariantTests {
    /// The environment variable that makes the tests write their output as new expectations.
    static let recordVariable = "JAVA_CLASS_VARIANT_RECORD"

    @Test("Generated classes match the reviewed expectations", arguments: JavaClassVariant.all)
    @MainActor
    func goldenFiles(_ variant: JavaClassVariant) async throws {
        let generated = try await GeneratedProject.make(
            variant.fixture, stem: variant.stem, options: variant.options)
        defer { generated.remove() }
        var text = try String(contentsOf: generated.genModel, encoding: .utf8)
        let marker = "<genmodel:GenModel "
        let range = try #require(text.range(of: marker))
        text.replaceSubrange(range, with: marker + variant.attributes + " ")
        try text.write(to: generated.genModel, atomically: true, encoding: .utf8)
        try await generated.generate()

        for path in variant.files {
            let actual = try generated.text(path)
            if let record = ProcessInfo.processInfo.environment[Self.recordVariable] {
                let target = URL(fileURLWithPath: record).appendingPathComponent(variant.name)
                    .appendingPathComponent(path)
                try FileManager.default.createDirectory(
                    at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                try actual.write(to: target, atomically: true, encoding: .utf8)
                continue
            }
            let expected = try String(
                contentsOf: Fixtures.url(
                    of: "\(variant.fixture)/expected-java-variants/\(variant.name)/\(path)"),
                encoding: .utf8)
            #expect(actual == expected, "\(path) differs from its expectation for \(variant.name)")
        }
    }
}
