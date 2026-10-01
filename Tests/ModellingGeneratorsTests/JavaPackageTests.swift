import Foundation
import Testing

@testable import ModellingGenerators

/// Tests of the package interface and package implementation templates for settings beyond the fixtures' defaults.
@Suite("Java package templates")
struct JavaPackageTests {
    /// The options that every test of this suite imports the library fixture with.
    static let options = GenModelImportOptions(basePackage: "org.example")

    /// The location of the generated package interface of the library fixture.
    static let interfacePath = "org/example/library/LibraryPackage.java"

    /// The location of the generated package implementation of the library fixture.
    static let implementationPath = "org/example/library/impl/LibraryPackageImpl.java"

    /// Generates the library fixture after changing the attributes of its generator model.
    ///
    /// - Parameter edit: A function that edits the text of the generator model.
    /// - Returns: The generated project, which the caller removes.
    @MainActor
    static func generateLibrary(edit: (String) -> String) async throws -> GeneratedProject {
        let generated = try await GeneratedProject.make("library", stem: "library", options: options)
        let text = try String(contentsOf: generated.genModel, encoding: .utf8)
        try edit(text).write(to: generated.genModel, atomically: true, encoding: .utf8)
        try await generated.generate()
        return generated
    }

    @Test("A package that loads its metadata writes its serialised form and loading code")
    @MainActor
    func loadInitialization() async throws {
        let generated = try await Self.generateLibrary {
            $0.replacingOccurrences(of: "<genPackages ", with: "<genPackages loadInitialization=\"true\" ")
        }
        defer { generated.remove() }
        let implementation = try generated.text(Self.implementationPath)
        #expect(implementation.contains("protected String packageFilename = \"library.ecore\";"))
        #expect(implementation.contains("theLibraryPackage.loadPackage();"))
        #expect(implementation.contains("theLibraryPackage.fixPackageContents();"))
        #expect(implementation.contains("public void loadPackage()"))
        #expect(!implementation.contains("createPackageContents"))
        let serialised = try generated.text("org/example/library/impl/library.ecore")
        #expect(serialised.contains("<ecore:EPackage"))
        #expect(serialised.contains("name=\"Library\""))
        #expect(generated.generatedPaths().contains("org/example/library/impl/library.ecore"))
    }

    @Test("Without operation reflection operations are added to classes directly")
    @MainActor
    func withoutOperationReflection() async throws {
        let generated = try await Self.generateLibrary {
            $0.replacingOccurrences(of: "operationReflection=\"true\"", with: "operationReflection=\"false\"")
        }
        defer { generated.remove() }
        let implementation = try generated.text(Self.implementationPath)
        #expect(implementation.contains("addEOperation(libraryEClass, this.getBook(), \"findBooks\", 0, -1, IS_UNIQUE, IS_ORDERED);"))
        #expect(!implementation.contains("initEOperation"))
        let interface = try generated.text(Self.interfacePath)
        #expect(!interface.contains("OPERATION_COUNT"))
    }

    @Test("With operation reflection operations have identifiers and accessors")
    @MainActor
    func withOperationReflection() async throws {
        let generated = try await GeneratedProject.make("library", stem: "library", options: Self.options)
        defer { generated.remove() }
        try await generated.generate()
        let interface = try generated.text(Self.interfacePath)
        #expect(interface.contains("int LIBRARY___FIND_BOOKS__STRING_INT = NAMED_OPERATION_COUNT + 0;"))
        #expect(interface.contains("int LIBRARY_OPERATION_COUNT = NAMED_OPERATION_COUNT + 1;"))
        #expect(interface.contains("EOperation getLibrary__FindBooks__String_int();"))
        let implementation = try generated.text(Self.implementationPath)
        #expect(implementation.contains("initEOperation(getLibrary__FindBooks__String_int(), this.getBook(), \"findBooks\", 0, -1, IS_UNIQUE, IS_ORDERED);"))
        #expect(implementation.contains("addEParameter(op, ecorePackage.getEString(), \"title\", 0, 1, IS_UNIQUE, IS_ORDERED);"))
    }

    @Test("Without a literals interface the nested interface is left out")
    @MainActor
    func withoutLiteralsInterface() async throws {
        let generated = try await Self.generateLibrary {
            $0.replacingOccurrences(of: "<genPackages ", with: "<genPackages literalsInterface=\"false\" ")
        }
        defer { generated.remove() }
        #expect(!(try generated.text(Self.interfacePath)).contains("interface Literals"))
    }

    @Test("Data types and enumerations have accessors, creation and initialisation")
    @MainActor
    func dataTypesAndEnumerations() async throws {
        let generated = try await GeneratedProject.make("library", stem: "library", options: Self.options)
        defer { generated.remove() }
        try await generated.generate()
        let implementation = try generated.text(Self.implementationPath)
        #expect(implementation.contains("isbnEDataType = createEDataType(ISBN);"))
        #expect(implementation.contains("initEDataType(isbnEDataType, String.class, \"ISBN\", IS_SERIALIZABLE, !IS_GENERATED_INSTANCE_CLASS);"))
        #expect(implementation.contains("addEEnumLiteral(bookCategoryEEnum, BookCategory.MYSTERY);"))
        #expect(implementation.contains("initEClass(lendableEClass, Lendable.class, \"Lendable\", IS_ABSTRACT, IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);"))
    }

    @Test("Interfaces and metadata can be suppressed, which merges the package into one class")
    @MainActor
    func suppressedInterfaces() async throws {
        let generated = try await Self.generateLibrary {
            $0.replacingOccurrences(of: "<genmodel:GenModel ", with: "<genmodel:GenModel suppressInterfaces=\"true\" ")
        }
        defer { generated.remove() }
        let paths = generated.generatedPaths().filter { $0.contains("Package") }
        #expect(paths == [Self.interfacePath])
        let text = try generated.text(Self.interfacePath)
        #expect(text.contains("public class LibraryPackage extends EPackageImpl"))
        #expect(text.contains("public static final String eNS_URI"))
    }

    @Test("Annotations other than documentation are created from their source")
    @MainActor
    func annotations() async throws {
        let generated = try await GeneratedProject.make("library", stem: "library", options: Self.options)
        defer { generated.remove() }
        try await generated.generate()
        #expect(!(try generated.text(Self.implementationPath)).contains("createGenModelAnnotations"))
    }
}
