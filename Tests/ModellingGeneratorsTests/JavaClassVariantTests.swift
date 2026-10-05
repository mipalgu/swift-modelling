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
            options: GenModelImportOptions(basePackage: "org.example", defaults: .wizard, operationReflection: false),
            attributes: "", files: ["org/example/library/impl/LibraryImpl.java"]),
        JavaClassVariant(
            name: "all-reflective-methods", fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes", defaults: .wizard),
            attributes: #"minimalReflectiveMethods="false" switchMissingDefaultCase="true""#,
            files: ["org/example/shapes/classes/impl/CircleImpl.java"]),
        JavaClassVariant(
            name: "boolean-flags", fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes", defaults: .wizard),
            attributes: #"booleanFlagsField="eFlags" booleanFlagsReservedBits="8""#,
            files: ["org/example/shapes/classes/impl/ShapeImpl.java", "org/example/shapes/classes/impl/CircleImpl.java"]),
        JavaClassVariant(
            name: "public-constructors-without-notification", fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes", defaults: .wizard),
            attributes: #"publicConstructors="true" suppressNotification="true" nonNLSMarkers="true""#,
            files: ["org/example/shapes/classes/impl/CanvasImpl.java"]),
    ]
}

@Suite("Java classes with other generator model settings")
struct JavaClassVariantTests {
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
            try GoldenFiles.check(
                try generated.text(path), against: "\(variant.fixture)/expected-java-variants/\(variant.name)/\(path)",
                "\(path) for \(variant.name)")
        }
    }
}
