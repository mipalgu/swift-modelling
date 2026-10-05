import Foundation
import Testing

@testable import ModellingGenerators

/// A fixture together with the utility files (switch, adapter factory, validator) that the Java template set must generate for it.
struct JavaUtilityCase: Sendable, CustomTestStringConvertible {
    /// The name of the fixture directory.
    let fixture: String

    /// The file stem of the source model.
    let stem: String

    /// The import options that the expectations were reviewed for.
    let options: GenModelImportOptions

    /// The expected utility files, relative to the generated source root.
    let files: [String]

    var testDescription: String { fixture }

    /// The marker of the utility package in a generated path.
    static let utilityDirectory = "/util/"

    /// Every fixture with its expected utility files.
    static let all: [JavaUtilityCase] = [
        JavaUtilityCase(
            fixture: "library", stem: "library",
            options: GenModelImportOptions(basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd", defaults: .wizard),
            files: [
                "org/example/library/util/LibraryAdapterFactory.java",
                "org/example/library/util/LibrarySwitch.java",
            ]),
        JavaUtilityCase(
            fixture: "nested", stem: "company",
            options: GenModelImportOptions(basePackage: "org.example.company", packagePrefixes: ["projects": "Proj"]),
            files: [
                "org/example/company/company/people/util/PeopleAdapterFactory.java",
                "org/example/company/company/people/util/PeopleSwitch.java",
                "org/example/company/company/projects/archive/util/ArchiveAdapterFactory.java",
                "org/example/company/company/projects/archive/util/ArchiveSwitch.java",
                "org/example/company/company/projects/util/ProjAdapterFactory.java",
                "org/example/company/company/projects/util/ProjSwitch.java",
                "org/example/company/company/util/CompanyAdapterFactory.java",
                "org/example/company/company/util/CompanySwitch.java",
            ]),
        JavaUtilityCase(
            fixture: "enumerations", stem: "enumerations",
            options: GenModelImportOptions(basePackage: "org.example.traffic"),
            files: [
                "org/example/traffic/enumerations/util/EnumerationsAdapterFactory.java",
                "org/example/traffic/enumerations/util/EnumerationsSwitch.java",
            ]),
        JavaUtilityCase(
            fixture: "documented", stem: "documented",
            options: GenModelImportOptions(basePackage: "org.example.alarm"),
            files: []),
        JavaUtilityCase(
            fixture: "families", stem: "families",
            options: GenModelImportOptions(basePackage: "org.example.families"),
            files: [
                "org/example/families/Families/util/FamiliesAdapterFactory.java",
                "org/example/families/Families/util/FamiliesSwitch.java",
            ]),
        JavaUtilityCase(
            fixture: "organisation", stem: "organisation",
            options: GenModelImportOptions(basePackage: "org.example.organisation"),
            files: [
                "org/example/organisation/organisation/util/OrganisationAdapterFactory.java",
                "org/example/organisation/organisation/util/OrganisationSwitch.java",
            ]),
        JavaUtilityCase(
            fixture: "ecoretypes", stem: "bridge",
            options: GenModelImportOptions(basePackage: "org.example.bridge"),
            files: [
                "org/example/bridge/bridge/util/BridgeAdapterFactory.java",
                "org/example/bridge/bridge/util/BridgeSwitch.java",
            ]),
        JavaUtilityCase(
            fixture: "classes", stem: "classes",
            options: GenModelImportOptions(basePackage: "org.example.shapes", defaults: .wizard),
            files: [
                "org/example/shapes/classes/util/ClassesAdapterFactory.java",
                "org/example/shapes/classes/util/ClassesSwitch.java",
            ]),
        JavaUtilityCase(
            fixture: "maps", stem: "maps",
            options: GenModelImportOptions(),
            files: [
                "maps/util/MapsAdapterFactory.java",
                "maps/util/MapsSwitch.java",
            ]),
        JavaUtilityCase(
            fixture: "constraints", stem: "constraints",
            options: GenModelImportOptions(basePackage: "org.example.bank"),
            files: [
                "org/example/bank/bank/util/BankAdapterFactory.java",
                "org/example/bank/bank/util/BankSwitch.java",
                "org/example/bank/bank/util/BankValidator.java",
            ]),
    ]
}

@Suite("Java utility classes")
struct JavaUtilityGenerationTests {
    @Test("Generated switches, adapter factories and validators match the reviewed expectations", arguments: JavaUtilityCase.all)
    @MainActor
    func goldenFiles(_ golden: JavaUtilityCase) async throws {
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options)
        defer { generated.remove() }
        try await generated.generate()

        let utilityPaths = generated.generatedPaths().filter { $0.contains(JavaUtilityCase.utilityDirectory) }
        let missing = Set(golden.files).subtracting(utilityPaths)
        #expect(missing.isEmpty, "missing generated files: \(missing.sorted())")
        for path in golden.files {
            let expected = try String(contentsOf: generated.project.javaExpectation(path), encoding: .utf8)
            #expect(try generated.text(path) == expected, "\(path) differs from its expectation")
        }
    }

    @Test("A package without classes has no switch or adapter factory")
    @MainActor
    func packageWithoutClasses() async throws {
        let generated = try await GeneratedProject.make(
            "documented", stem: "documented", options: GenModelImportOptions(basePackage: "org.example.alarm"))
        defer { generated.remove() }
        try await generated.generate()
        #expect(!generated.generatedPaths().contains { $0.contains(JavaUtilityCase.utilityDirectory) })
    }

    @Test("Only a package with constraints has a validator")
    @MainActor
    func validatorOnlyWithConstraints() async throws {
        for golden in JavaUtilityCase.all {
            let hasValidator = golden.files.contains { $0.hasSuffix("Validator.java") }
            #expect(hasValidator == (golden.fixture == "constraints"), "\(golden.fixture)")
        }
    }

    @Test("A package that asks for no adapter factory has no switch or adapter factory")
    @MainActor
    func adapterFactorySwitchedOff() async throws {
        let generated = try await GeneratedProject.make(
            "library", stem: "library", options: GenModelImportOptions(basePackage: "org.example", defaults: .wizard))
        defer { generated.remove() }
        let text = try String(contentsOf: generated.genModel, encoding: .utf8)
        try text.replacingOccurrences(of: "<genPackages ", with: "<genPackages adapterFactory=\"false\" ")
            .write(to: generated.genModel, atomically: true, encoding: .utf8)
        try await generated.generate()
        #expect(!generated.generatedPaths().contains { $0.contains(JavaUtilityCase.utilityDirectory) })
    }

    @Test("Generating twice yields identical utility files")
    @MainActor
    func determinism() async throws {
        let golden = try #require(JavaUtilityCase.all.first { $0.fixture == "constraints" })
        let generated = try await GeneratedProject.make(golden.fixture, stem: golden.stem, options: golden.options)
        defer { generated.remove() }
        try await generated.generate()
        let first = try golden.files.map { try generated.text($0) }
        try FileManager.default.removeItem(at: generated.output)
        try await generated.generate()
        let second = try golden.files.map { try generated.text($0) }
        #expect(first == second)
    }

    @Test("Progress counts the utility files")
    @MainActor
    func progressCounts() async throws {
        let golden = try #require(JavaUtilityCase.all.first { $0.fixture == "constraints" })
        let generated = try await GeneratedProject.make(golden.fixture, stem: golden.stem, options: golden.options)
        defer { generated.remove() }
        let collector = ProgressCollector()
        try await generated.generate(progress: { collector.add($0) })
        let fileUpdates = collector.updates.filter { $0.message.hasPrefix("Generated ") }
        #expect(fileUpdates.count == generated.generatedPaths().count)
        #expect(fileUpdates.allSatisfy { $0.total == fileUpdates.count })
    }
}
