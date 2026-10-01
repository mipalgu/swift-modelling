import Foundation
import Testing

@testable import ModellingGenerators

/// Generator model settings that change the form of the generated factories.
struct FactoryVariant: Sendable, CustomTestStringConvertible {
    /// The name of the directory that holds the expectations, below `expected-java-`.
    let name: String

    /// The text of the generator model that the setting is inserted before.
    let anchor: String

    /// The text that is inserted.
    let insertion: String

    var testDescription: String { name }

    /// The variants that the data types fixture is checked with.
    static let all: [FactoryVariant] = [
        FactoryVariant(
            name: "converters", anchor: "<genPackages ", insertion: "dataTypeConverters=\"true\" "),
        FactoryVariant(
            name: "codestyle", anchor: "<genmodel:GenModel ",
            insertion:
                "nonNLSMarkers=\"true\" codeStyle=\"UnnecessaryAssignmentBeforeReturn UnnecessaryDeprecatedMethod\" "
        ),
    ]
}

@Suite("Java factory template")
struct JavaFactoryTemplateTests {
    /// The factory files of the data types fixture, relative to the source root.
    static let files = [
        "org/example/types/datatypes/DatatypesFactory.java",
        "org/example/types/datatypes/impl/DatatypesFactoryImpl.java",
    ]

    /// Generates the data types fixture from a generator model with a changed setting.
    @MainActor
    static func generate(_ variant: FactoryVariant?) async throws -> GeneratedProject {
        let generated = try await GeneratedProject.make(
            "datatypes", stem: "datatypes", options: GenModelImportOptions(basePackage: "org.example.types"))
        if let variant {
            var text = try String(contentsOf: generated.genModel, encoding: .utf8)
            let range = try #require(text.range(of: variant.anchor))
            text.insert(contentsOf: variant.insertion, at: range.upperBound)
            try text.write(to: generated.genModel, atomically: true, encoding: .utf8)
        }
        try await generated.generate()
        return generated
    }

    @Test("Settings change the form of the generated factories", arguments: FactoryVariant.all)
    @MainActor
    func variants(_ variant: FactoryVariant) async throws {
        let generated = try await Self.generate(variant)
        defer { generated.remove() }
        for path in Self.files {
            let expected = try String(
                contentsOf: Fixtures.url(of: "datatypes/expected-java-\(variant.name)/\(path)"), encoding: .utf8)
            #expect(try generated.text(path) == expected, "\(path) differs for \(variant.name)")
        }
    }

    @Test("Create and convert bodies of the model are written with their imports")
    @MainActor
    func bodiesAreWritten() async throws {
        let generated = try await Self.generate(nil)
        defer { generated.remove() }
        let text = try generated.text(Self.files[1])
        #expect(text.contains("return new Date(Long.parseLong(it));\n    // done"))
        #expect(text.contains("import java.util.Date;"))
        #expect(!text.contains("<%"))
    }

    @Test("A data type that is not serializable has no conversion methods")
    @MainActor
    func unserialisableTypeIsLeftOut() async throws {
        let generated = try await Self.generate(nil)
        defer { generated.remove() }
        let text = try generated.text(Self.files[1])
        #expect(!text.contains("Hidden"))
    }

    @Test("A class named like a type of the language makes the implementation import its types one by one")
    @MainActor
    func conflictAvoidsWildcard() async throws {
        let generated = try await Self.generate(nil)
        defer { generated.remove() }
        let text = try generated.text(Self.files[1])
        #expect(!text.contains(".*;"))
        #expect(text.contains("public org.example.types.datatypes.Class createClass()"))
    }

    @Test("Deprecated classes carry the deprecation tags and annotations")
    @MainActor
    func deprecationIsCarried() async throws {
        let generated = try await Self.generate(nil)
        defer { generated.remove() }
        let text = try generated.text(Self.files[1])
        #expect(text.contains("@SuppressWarnings(\"deprecation\")"))
        #expect(text.contains("@deprecated See {@link Gizmo model documentation} for details."))
        let interface = try generated.text(Self.files[0])
        #expect(interface.contains("@since 2.0"))
    }
}

/// Compiles generated factories against stand-ins for the files of the other templates.
@Suite("Compiling generated factories")
struct JavaFactoryCompileTests {
    /// The package of the data types fixture.
    static let packageName = "org.example.types.datatypes"

    /// Source of the class interfaces and implementations that the factories need, which no template writes yet.
    static let stubs: [String: String] = [
        "Thing": "public interface Thing extends org.eclipse.emf.ecore.EObject {}",
        "Class": "public interface Class extends org.eclipse.emf.ecore.EObject {}",
        "Gizmo": "public interface Gizmo extends org.eclipse.emf.ecore.EObject {}",
        "impl/ThingImpl": implementation("Thing"),
        "impl/ClassImpl": implementation("Class"),
        "impl/GizmoImpl": implementation("Gizmo"),
    ]

    /// Source of a stand-in implementation class.
    ///
    /// - Parameter name: The name of the interface it implements.
    /// - Returns: The source text.
    static func implementation(_ name: String) -> String {
        "public class \(name)Impl extends org.eclipse.emf.ecore.impl.MinimalEObjectImpl.Container implements "
            + "org.example.types.datatypes.\(name) {}"
    }

    @Test(
        "Factories compile for each form of the data types fixture",
        .enabled(
            if: JavaCompileTests.classPath != nil, "EMF_RUNTIME_CLASSPATH is not set; skipping the compile test"),
        .enabled(if: JavaCompileTests.compiler != nil, "No javac found; skipping the compile test"),
        arguments: [nil] + FactoryVariant.all.map { Optional($0) }
    )
    @MainActor
    func compiles(_ variant: FactoryVariant?) async throws {
        let classPath = try #require(JavaCompileTests.classPath)
        let generated = try await JavaFactoryTemplateTests.generate(variant)
        defer { generated.remove() }
        let directory = generated.output
        for (name, body) in Self.stubs {
            let isImplementation = name.hasPrefix("impl/")
            let header = "package \(Self.packageName)\(isImplementation ? ".impl" : "");\n"
            let file = directory.appendingPathComponent("stubs/org/example/types/datatypes/\(name).java")
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try (header + body + "\n").write(to: file, atomically: true, encoding: .utf8)
        }
        let stubFiles = Self.stubs.keys.map {
            directory.appendingPathComponent("stubs/org/example/types/datatypes/\($0).java")
        }
        let classes = directory.appendingPathComponent("classes")
        try FileManager.default.createDirectory(at: classes, withIntermediateDirectories: true)
        let files = generated.generatedPaths().map { generated.file($0) } + stubFiles
        let (status, text) = try JavaCompileTests.compile(files, into: classes, classPath: classPath)
        #expect(status == 0, "javac failed:\n\(text)")
    }
}
