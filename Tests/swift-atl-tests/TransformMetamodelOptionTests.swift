//
// TransformMetamodelOptionTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Checks the options of `swift-atl transform` that give metamodel files, select refining mode,
/// only validate, and keep the command quiet.
@Suite("swift-atl transform - metamodel files, refining, validation and quiet output")
struct TransformMetamodelOptionTests {
    /// A working directory with the Families2Persons transformation, its metamodels under other
    /// file names, and a sample model.
    struct Project {
        /// The scratch directory.
        let directory: URL

        /// The Families metamodel, saved as `mm/fam.ecore`.
        let families: URL

        /// The Persons metamodel, saved as `mm/per.ecore`.
        let persons: URL

        /// The sample Families model.
        let model: URL

        /// Removes the scratch directory.
        func remove() { cleanupTemporaryDirectory(directory) }

        /// The location of a file in the scratch directory.
        ///
        /// - Parameter name: The relative path of the file.
        /// - Returns: The location of the file.
        func file(_ name: String) -> URL { directory.appendingPathComponent(name) }

        /// Writes an ATL transformation into the scratch directory.
        ///
        /// - Parameters:
        ///   - text: The text of the transformation.
        ///   - name: The file name.
        /// - Returns: The location of the transformation.
        func write(_ text: String, as name: String) throws -> URL {
            let url = file(name)
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        }
    }

    /// Creates a project whose metamodel file names match no `@path` directive.
    private func makeProject() throws -> Project {
        let directory = try createTemporaryDirectory()
        let metamodels = directory.appendingPathComponent("mm")
        try FileManager.default.createDirectory(at: metamodels, withIntermediateDirectories: true)
        let families = metamodels.appendingPathComponent("fam.ecore")
        let persons = metamodels.appendingPathComponent("per.ecore")
        let model = directory.appendingPathComponent("sample-Families.xmi")
        try FileManager.default.copyItem(
            at: try loadTestResource(named: "Families.ecore", subdirectory: "Families2Persons"), to: families)
        try FileManager.default.copyItem(
            at: try loadTestResource(named: "Persons.ecore", subdirectory: "Families2Persons"), to: persons)
        try FileManager.default.copyItem(
            at: try loadTestResource(named: "sample-Families.xmi", subdirectory: "models"), to: model)
        return Project(directory: directory, families: families, persons: persons, model: model)
    }

    /// The Families2Persons transformation with its `@path` directives replaced.
    ///
    /// - Parameter header: The directives that take the place of the original ones.
    /// - Returns: The text of the transformation.
    private func families2Persons(header: String = "") throws -> String {
        let original = try String(
            contentsOf: try loadTestResource(named: "Families2Persons.atl", subdirectory: "transformations"),
            encoding: .utf8)
        let body = original.split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.hasPrefix("-- @path") }
            .joined(separator: "\n")
        return header + "\n" + body
    }

    /// A transformation that copies families and changes their last names, in place when refining.
    ///
    /// - Parameter keyword: `from` or `refining`.
    /// - Returns: The text of the transformation.
    private func upperCaseFamilies(_ keyword: String) -> String {
        """
        module UpperCaseFamilies;
        create OUT : Families \(keyword) IN : Families;

        rule Family {
            from s : Families!Family
            to t : Families!Family (
                lastName <- s.lastName.toUpper()
            )
        }
        """
    }

    /// The combined output of a run.
    private func output(_ result: SubprocessResult) -> String { result.stdout + result.stderr }

    // MARK: - Metamodel files

    @Test("binds source and target metamodels to files given by position")
    @MainActor
    func positionalMetamodelFiles() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(try families2Persons(), as: "F2P.atl")
        let target = project.file("persons.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", target.path,
                "--source-metamodel", project.families.path, "--target-metamodel", project.persons.path,
            ])

        #expect(result.succeeded, "\(output(result))")
        let text = try String(contentsOf: target, encoding: .utf8)
        #expect(text.contains("Jim March"), "\(text)")
        #expect(text.contains("Female"), "\(text)")
    }

    @Test("binds metamodels by name and takes precedence over @path directives")
    @MainActor
    func namedMetamodelFilesOverrideDirectives() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let header = """
            -- @path Families=/Elsewhere/Missing.ecore
            -- @path Persons=/Elsewhere/Missing.ecore
            """
        let atl = try project.write(try families2Persons(header: header), as: "F2P.atl")
        let target = project.file("persons.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", "IN=\(project.model.path)", "--target", "OUT=\(target.path)",
                "--target-metamodel", "Persons=\(project.persons.path)",
                "--source-metamodel", "Families=\(project.families.path)",
            ])

        #expect(result.succeeded, "\(output(result))")
        #expect(try String(contentsOf: target, encoding: .utf8).contains("Brandon March"))
    }

    @Test("binds a metamodel shared by source and target with --metamodel")
    @MainActor
    func sharedMetamodelFile() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(upperCaseFamilies("from"), as: "Upper.atl")
        let target = project.file("families.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", target.path,
                "--metamodel", project.families.path,
            ])

        #expect(result.succeeded, "\(output(result))")
        #expect(try String(contentsOf: target, encoding: .utf8).contains("lastName=\"MARCH\""))
    }

    @Test("reports a metamodel name that the module does not declare")
    @MainActor
    func unknownMetamodelName() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(try families2Persons(), as: "F2P.atl")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", project.file("out.xmi").path,
                "--source-metamodel", "Animals=\(project.families.path)",
                "--target-metamodel", project.persons.path,
            ])

        #expect(!result.succeeded)
        #expect(output(result).contains("'Animals'"), "\(output(result))")
        #expect(output(result).contains("Families"), "\(output(result))")
    }

    @Test("reports a positional metamodel list of the wrong length")
    @MainActor
    func positionalCountMismatch() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(try families2Persons(), as: "F2P.atl")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", project.file("out.xmi").path,
                "--source-metamodel", project.families.path, "--source-metamodel", project.persons.path,
                "--target-metamodel", project.persons.path,
            ])

        #expect(!result.succeeded)
        #expect(output(result).contains("--source-metamodel"), "\(output(result))")
    }

    @Test("reports a metamodel that two options bind to different files")
    @MainActor
    func conflictingMetamodelFiles() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(upperCaseFamilies("from"), as: "Upper.atl")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", project.file("out.xmi").path,
                "--source-metamodel", project.families.path, "--target-metamodel", project.persons.path,
            ])

        #expect(!result.succeeded)
        #expect(output(result).contains("'Families'"), "\(output(result))")
    }

    @Test("reports a metamodel that neither a file nor a directive binds")
    @MainActor
    func unboundMetamodel() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(try families2Persons(), as: "F2P.atl")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", project.file("out.xmi").path,
                "--source-metamodel", project.families.path,
            ])

        #expect(!result.succeeded)
        #expect(output(result).contains("'Persons'"), "\(output(result))")
    }

    @Test("reports a metamodel file that does not exist")
    @MainActor
    func missingMetamodelFile() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(upperCaseFamilies("from"), as: "Upper.atl")
        let missing = project.file("missing.ecore")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", project.file("out.xmi").path,
                "--metamodel", missing.path,
            ])

        #expect(!result.succeeded)
        #expect(output(result).contains(missing.path), "\(output(result))")
    }

    // MARK: - Refining mode

    @Test("refines the source model with --refining, keeping what no rule changes")
    @MainActor
    func refiningOption() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(upperCaseFamilies("from"), as: "Upper.atl")
        let target = project.file("families.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", target.path,
                "--metamodel", project.families.path, "--refining",
            ])

        #expect(result.succeeded, "\(output(result))")
        let text = try String(contentsOf: target, encoding: .utf8)
        #expect(text.contains("lastName=\"MARCH\""), "\(text)")
        #expect(text.contains("firstName=\"Brandon\""), "\(text)")
    }

    @Test("refines a module whose header declares refining mode")
    @MainActor
    func refiningHeader() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(upperCaseFamilies("refining"), as: "Upper.atl")
        let target = project.file("families.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", target.path,
                "--metamodel", project.families.path,
            ])

        #expect(result.succeeded, "\(output(result))")
        let text = try String(contentsOf: target, encoding: .utf8)
        #expect(text.contains("lastName=\"SAILOR\""), "\(text)")
        #expect(text.contains("firstName=\"Kelly\""), "\(text)")
    }

    @Test("does not copy unmatched elements without refining mode")
    @MainActor
    func noRefiningWithoutOption() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(upperCaseFamilies("from"), as: "Upper.atl")
        let target = project.file("families.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", target.path,
                "--metamodel", project.families.path,
            ])

        #expect(result.succeeded, "\(output(result))")
        #expect(!(try String(contentsOf: target, encoding: .utf8)).contains("firstName"))
    }

    @Test("drops matched elements in refining mode")
    @MainActor
    func dropInRefiningMode() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(
            """
            module DropMarch;
            create OUT : Families refining IN : Families;

            rule March {
                from s : Families!Family (s.lastName = 'March')
                to drop
            }
            """, as: "Drop.atl")
        let target = project.file("families.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", target.path,
                "--metamodel", project.families.path,
            ])

        #expect(result.succeeded, "\(output(result))")
        let text = try String(contentsOf: target, encoding: .utf8)
        #expect(!text.contains("March"), "\(text)")
        #expect(!text.contains("Brandon"), "\(text)")
        #expect(text.contains("lastName=\"Sailor\""), "\(text)")
    }

    // MARK: - Validation only

    @Test("validates without running the transformation or writing targets")
    @MainActor
    func validateOnly() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(try families2Persons(), as: "F2P.atl")
        let target = project.file("persons.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", target.path,
                "--source-metamodel", project.families.path, "--target-metamodel", project.persons.path,
                "--validate-only",
            ])

        #expect(result.succeeded, "\(output(result))")
        #expect(result.stdout.contains("Families2Persons"), "\(output(result))")
        #expect(result.stdout.contains("valid"), "\(output(result))")
        #expect(!FileManager.default.fileExists(atPath: target.path))
    }

    @Test("validates a transformation without any models")
    @MainActor
    func validateOnlyWithoutModels() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(upperCaseFamilies("refining"), as: "Upper.atl")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [atl.path, "--metamodel", project.families.path, "--validate-only"])

        #expect(result.succeeded, "\(output(result))")
    }

    @Test("reports a type that the bound metamodel does not define")
    @MainActor
    func validateOnlyUnknownType() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let text = upperCaseFamilies("from").replacingOccurrences(
            of: "to t : Families!Family", with: "to t : Families!Household")
        let atl = try project.write(text, as: "Upper.atl")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [atl.path, "--metamodel", project.families.path, "--validate-only"])

        #expect(!result.succeeded)
        #expect(output(result).contains("Families!Household"), "\(output(result))")
    }

    @Test("reports a binding of a feature that the target class does not have")
    @MainActor
    func validateOnlyUnknownFeature() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let text = upperCaseFamilies("from").replacingOccurrences(of: "lastName <-", with: "surname <-")
        let atl = try project.write(text, as: "Upper.atl")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [atl.path, "--metamodel", project.families.path, "--validate-only"])

        #expect(!result.succeeded)
        #expect(output(result).contains("'surname'"), "\(output(result))")
    }

    @Test("reports drop outside refining mode")
    @MainActor
    func validateOnlyDropOutsideRefining() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let text = upperCaseFamilies("from") + "\nrule Drop { from m : Families!Member to drop }\n"
        let atl = try project.write(text, as: "Upper.atl")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [atl.path, "--metamodel", project.families.path, "--validate-only"])
        let refining = try await executeSwiftATL(
            command: "transform",
            arguments: [atl.path, "--metamodel", project.families.path, "--validate-only", "--refining"])

        #expect(!result.succeeded)
        #expect(output(result).contains("Rule 'Drop'"), "\(output(result))")
        #expect(output(result).contains("refining"), "\(output(result))")
        #expect(refining.succeeded, "\(output(refining))")
    }

    @Test("reports a source model that does not exist")
    @MainActor
    func validateOnlyMissingModel() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(upperCaseFamilies("refining"), as: "Upper.atl")
        let missing = project.file("missing.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", missing.path, "--metamodel", project.families.path, "--validate-only",
            ])

        #expect(!result.succeeded)
        #expect(output(result).contains(missing.path), "\(output(result))")
    }

    // MARK: - Quiet output

    @Test("prints nothing on success with --quiet")
    @MainActor
    func quiet() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(upperCaseFamilies("from"), as: "Upper.atl")
        let target = project.file("families.xmi")

        let result = try await executeSwiftATL(
            command: "transform",
            arguments: [
                atl.path, "--source", project.model.path, "--target", target.path,
                "--metamodel", project.families.path, "--quiet",
            ])

        #expect(result.succeeded, "\(output(result))")
        #expect(result.stdout.isEmpty, "\(result.stdout)")
        #expect(FileManager.default.fileExists(atPath: target.path))
    }

    @Test("rejects --quiet together with --verbose")
    @MainActor
    func quietAndVerbose() async throws {
        let project = try makeProject()
        defer { project.remove() }
        let atl = try project.write(upperCaseFamilies("from"), as: "Upper.atl")

        let result = try await executeSwiftATL(
            command: "transform", arguments: [atl.path, "--quiet", "--verbose"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("--quiet"), "\(result.stderr)")
    }
}
