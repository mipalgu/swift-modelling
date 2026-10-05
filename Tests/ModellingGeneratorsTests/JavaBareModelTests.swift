import Foundation
import Testing

@testable import ModellingGenerators

/// A package with one empty class: no enumerations, data types, features, operations, annotations or constraints.
///
/// Every list that the templates read is unset or empty, which must read as empty rather than as unknown.
@Suite("Java generation for a model with nothing but an empty class")
struct JavaBareModelTests {
    /// The base package of the generated code.
    static let basePackage = "org.example"

    /// The files that generating the model must write, relative to the generated source root.
    static let files = [
        "org/example/bare/Thing.java", "org/example/bare/BareFactory.java", "org/example/bare/BarePackage.java",
        "org/example/bare/impl/ThingImpl.java", "org/example/bare/impl/BareFactoryImpl.java",
        "org/example/bare/impl/BarePackageImpl.java", "org/example/bare/util/BareAdapterFactory.java",
        "org/example/bare/util/BareSwitch.java",
    ]

    /// The directory of the expectations of a preset, below the fixture.
    static func expectations(_ defaults: GenModelDefaults) -> String {
        defaults == .headless ? "expected-java" : "expected-java-wizard"
    }

    @Test("Generated files match the reviewed expectations", arguments: GenModelDefaults.allCases)
    @MainActor
    func goldenFiles(_ defaults: GenModelDefaults) async throws {
        let generated = try await GeneratedProject.make(
            "bare", stem: "bare",
            options: GenModelImportOptions(basePackage: Self.basePackage, defaults: defaults))
        defer { generated.remove() }
        try await generated.generate()

        #expect(generated.generatedPaths() == Self.files.sorted())
        for path in Self.files {
            let expected = try String(
                contentsOf: Fixtures.url(of: "bare/\(Self.expectations(defaults))/\(path)"), encoding: .utf8)
            #expect(try generated.text(path) == expected, "\(path) differs from its expectation")
        }
    }

    @Test("The interface package is imported as a whole unless imports are organised")
    @MainActor
    func wildcardImports() async throws {
        let wildcard = "import org.example.bare.*;"
        let utilities = Self.files.filter { $0.contains("/util/") || $0.hasSuffix("BareFactoryImpl.java") }
        for defaults in GenModelDefaults.allCases {
            let generated = try await GeneratedProject.make(
                "bare", stem: "bare",
                options: GenModelImportOptions(basePackage: Self.basePackage, defaults: defaults))
            defer { generated.remove() }
            try await generated.generate()
            for path in utilities {
                #expect(try generated.text(path).contains(wildcard) == (defaults == .headless), "\(path) \(defaults)")
            }
        }
    }

    @Test("Overrides win over the preset for the imports")
    @MainActor
    func overriddenImports() async throws {
        let wizardWithWildcards = try await GeneratedProject.make(
            "bare", stem: "bare",
            options: GenModelImportOptions(basePackage: Self.basePackage, defaults: .wizard, importOrganizing: false))
        defer { wizardWithWildcards.remove() }
        try await wizardWithWildcards.generate()
        #expect(try wizardWithWildcards.text("org/example/bare/util/BareSwitch.java").contains("import org.example.bare.*;"))

        let headlessWithImports = try await GeneratedProject.make(
            "bare", stem: "bare",
            options: GenModelImportOptions(basePackage: Self.basePackage, importOrganizing: true))
        defer { headlessWithImports.remove() }
        try await headlessWithImports.generate()
        let text = try headlessWithImports.text("org/example/bare/util/BareSwitch.java")
        #expect(!text.contains("import org.example.bare.*;"))
        #expect(text.contains("import org.example.bare.BarePackage;"))
    }

    @Test("Operation reflection and the root class follow the preset")
    @MainActor
    func reflectionAndRootClass() async throws {
        let headless = try await GeneratedProject.make(
            "bare", stem: "bare", options: GenModelImportOptions(basePackage: Self.basePackage))
        defer { headless.remove() }
        try await headless.generate()
        let wizard = try await GeneratedProject.make(
            "bare", stem: "bare",
            options: GenModelImportOptions(basePackage: Self.basePackage, defaults: .wizard))
        defer { wizard.remove() }
        try await wizard.generate()
        let implementation = "org/example/bare/impl/ThingImpl.java"
        #expect(try headless.text(implementation).contains("extends EObjectImpl implements Thing"))
        #expect(try wizard.text(implementation).contains("extends MinimalEObjectImpl.Container implements Thing"))
        let package = "org/example/bare/BarePackage.java"
        #expect(!(try headless.text(package).contains("THING_OPERATION_COUNT")))
        #expect(try wizard.text(package).contains("THING_OPERATION_COUNT"))
    }
}
