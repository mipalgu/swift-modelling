//
// CompatibilityCheckOptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ArgumentParser
import Foundation
import ModelTyping
import ModellingCommandLine
import Testing

/// Small library metamodels, written to files by the tests that load them.
private enum LibraryMetamodel {
    /// The metamodel that the expressions of the tests are written against.
    static let original = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
        xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="library" \
        nsURI="http://example.org/library" nsPrefix="library">
          <eClassifiers xsi:type="ecore:EClass" name="Library">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" lowerBound="1" \
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EReference" name="books" upperBound="-1" \
        eType="#//Book" containment="true"/>
          </eClassifiers>
          <eClassifiers xsi:type="ecore:EClass" name="Book">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="title" lowerBound="1" \
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="pages" \
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EInt"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A revision that renames the books, widens the pages and makes the name optional.
    static let revised = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
        xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="library" \
        nsURI="http://example.org/library/2" nsPrefix="library">
          <eClassifiers xsi:type="ecore:EClass" name="Library">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" \
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EReference" name="volumes" upperBound="-1" \
        eType="#//Book" containment="true"/>
          </eClassifiers>
          <eClassifiers xsi:type="ecore:EClass" name="Book">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="title" lowerBound="1" \
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="pages" \
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//ELong"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// Writes both metamodels to a new directory.
    ///
    /// - Returns: The paths of the original and the revised metamodel.
    /// - Throws: An error if a file cannot be written.
    static func write() throws -> (original: String, revised: String) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("compatibility-check-tests").appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let original = directory.appendingPathComponent("Library.ecore")
        let revised = directory.appendingPathComponent("LibraryRevised.ecore")
        try Self.original.write(to: original, atomically: true, encoding: .utf8)
        try Self.revised.write(to: revised, atomically: true, encoding: .utf8)
        return (original.path, revised.path)
    }
}

/// The command line of a check of the `library` metamodel against a revision.
///
/// - Parameter extra: Further arguments.
/// - Returns: The arguments.
private func arguments(_ extra: [String] = []) -> [String] {
    ["--\(CompatibilityCheckOptions.OptionName.metamodel)", "library=a.ecore",
     "--\(CompatibilityCheckOptions.OptionName.targetMetamodel)", "library=b.ecore"] + extra
}

/// Checks an expression on `self : library::Library` against the revised library.
///
/// - Parameters:
///   - source: The expression.
///   - options: The options of the check.
/// - Returns: The report.
/// - Throws: An error if the metamodels cannot be loaded.
private func check(_ source: String, _ options: CompatibilityCheckOptions) async throws -> CompatibilityReport {
    let metamodels = try await options.loadMetamodels()
    let sole = try #require(metamodels.sole)
    let expression = try #require(AQLParser().parse(source).expression)
    return ReuseChecker.check(
        aql: expression, variables: ["self": "library::Library"], metamodelName: sole.name,
        required: sole.required, provided: sole.provided, mode: options.mode, options: try options.checkOptions())
}

/// Parses the options of a check of the written library metamodels.
///
/// - Parameters:
///   - extra: Further arguments.
///   - reversed: Whether the revision is checked against the original instead (default: `false`).
/// - Returns: The options.
/// - Throws: An error if the files cannot be written or the arguments are invalid.
private func libraryOptions(_ extra: [String] = [], reversed: Bool = false) throws -> CompatibilityCheckOptions {
    let files = try LibraryMetamodel.write()
    let (required, provided) = reversed ? (files.revised, files.original) : (files.original, files.revised)
    return try CompatibilityCheckOptions.parse(
        ["--metamodel", "library=\(required)", "--target-metamodel", "library=\(provided)"] + extra)
}

@Suite("Compatibility check options")
struct CompatibilityCheckOptionsTests {
    // MARK: - Spellings

    @Test("names the command and its options")
    func names() {
        #expect(CompatibilityCheckOptions.commandName == "check-compat")
        #expect(CompatibilityCheckOptions.OptionName.metamodel == "metamodel")
        #expect(CompatibilityCheckOptions.OptionName.targetMetamodel == "target-metamodel")
        #expect(CompatibilityCheckOptions.OptionName.mode == "mode")
        #expect(CompatibilityCheckOptions.OptionName.subtyping == "subtyping")
        #expect(CompatibilityCheckOptions.OptionName.rename == "rename")
        #expect(CompatibilityCheckOptions.OptionName.allowWidening == "allow-widening")
        #expect(CompatibilityCheckOptions.OptionName.lenientLowerBounds == "lenient-lower-bounds")
        #expect(CompatibilityCheckOptions.OptionName.format == "format")
    }

    @Test("spells the modes in kebab case")
    func modeSpellings() {
        #expect(SubtypingMode.allValueStrings == [
            "total-isomorphic", "total-non-isomorphic", "partial-isomorphic", "partial",
        ])
        #expect(SubtypingMode.totalNonIsomorphic.defaultValueDescription == "total-non-isomorphic")
        #expect(Set(SubtypingMode.allValueDescriptions.keys) == Set(SubtypingMode.allValueStrings))
    }

    @Test("reads each mode by its spelling", arguments: SubtypingMode.allCases)
    func modes(mode: SubtypingMode) throws {
        #expect(SubtypingMode(argument: mode.defaultValueDescription) == mode)
        let options = try CompatibilityCheckOptions.parse(arguments(["--mode", mode.defaultValueDescription]))
        #expect(options.mode == mode)
    }

    @Test("spells the matching semantics after the cases of the library")
    func semanticsSpellings() {
        #expect(MatchingSemantics.allValueStrings == ["object-type-matching", "mof-class-matching", "access-refined"])
        #expect(Set(MatchingSemantics.allValueDescriptions.keys) == Set(MatchingSemantics.allValueStrings))
        #expect(MatchingSemantics.objectTypeMatching.commandLineDescription.contains("steel-jezequel"))
        #expect(MatchingSemantics.mofClassMatching.commandLineDescription.contains("guy"))
    }

    @Test("reads each semantics by its spelling", arguments: MatchingSemantics.allCases)
    func semantics(semantics: MatchingSemantics) throws {
        let options = try CompatibilityCheckOptions.parse(
            arguments(["--subtyping", semantics.defaultValueDescription]))
        #expect(options.semantics == semantics)
    }

    @Test("reads the aliases named after the authors of the published definitions")
    func semanticsAliases() {
        #expect(MatchingSemantics(argument: "steel-jezequel") == .objectTypeMatching)
        #expect(MatchingSemantics(argument: "guy") == .mofClassMatching)
        #expect(CompatibilityCheckOptions.semanticsAliases == [
            "steel-jezequel": .objectTypeMatching, "guy": .mofClassMatching,
        ])
    }

    @Test("rejects values that name no mode or semantics", arguments: ["totalIsomorphic", "total", "", "standard"])
    func rejectsUnknownValues(value: String) {
        #expect(SubtypingMode(argument: value) == nil)
        #expect(MatchingSemantics(argument: value) == nil)
        #expect(throws: (any Error).self) { try CompatibilityCheckOptions.parse(arguments(["--mode", value])) }
        #expect(throws: (any Error).self) { try CompatibilityCheckOptions.parse(arguments(["--subtyping", value])) }
    }

    @Test("leaves --semantics to the standard or legacy preset of the other commands")
    func semanticsIsNotTheMatchingOption() {
        for value in MatchingSemantics.allValueStrings + ["steel-jezequel", "guy", "legacy"] {
            #expect(throws: (any Error).self) { try CompatibilityCheckOptions.parse(arguments(["--semantics", value])) }
        }
    }

    // MARK: - Defaults and conversion

    @Test("checks partially, with the access-refined semantics and as text, unless told otherwise")
    func defaults() throws {
        let options = try CompatibilityCheckOptions.parse(arguments())
        #expect(options.mode == .partial)
        #expect(options.semantics == .accessRefined)
        #expect(options.format == .text)
        let check = try options.checkOptions()
        #expect(check == CheckOptions())
        #expect(check.semantics == .accessRefined)
        #expect(try options.requiredMetamodelFiles() == ["library": "a.ecore"])
        #expect(try options.targetMetamodelFiles() == ["library": "b.ecore"])
    }

    @Test("passes renamings, widening, leniency and semantics to the check")
    func checkOptions() throws {
        let options = try CompatibilityCheckOptions.parse(arguments([
            "--rename", "Writer=Author", "--rename", "Book.isbn=ISBN,Library.writers=authors",
            "--allow-widening", "--lenient-lower-bounds", "--subtyping", "guy", "--format", "json",
        ]))
        let check = try options.checkOptions()
        #expect(check.renaming == Renaming(
            classifiers: ["Writer": "Author"], members: ["Book.isbn": "ISBN", "Library.writers": "authors"]))
        #expect(check.allowsNumericWidening)
        #expect(check.lenientLowerBounds)
        #expect(check.semantics == .mofClassMatching)
        #expect(options.format == .json)
    }

    // MARK: - Validation

    @Test("needs a metamodel and a target metamodel")
    func needsMetamodels() {
        #expect(throws: (any Error).self) {
            try CompatibilityCheckOptions.parse(["--target-metamodel", "library=b.ecore"])
        }
        #expect(throws: (any Error).self) { try CompatibilityCheckOptions.parse(["--metamodel", "library=a.ecore"]) }
    }

    @Test("rejects metamodels that are not given as name=file", arguments: ["a.ecore", "=a.ecore", "library="])
    func rejectsMalformedMetamodels(value: String) {
        #expect(throws: (any Error).self) {
            try CompatibilityCheckOptions.parse(["--metamodel", value, "--target-metamodel", "library=b.ecore"])
        }
        #expect(throws: (any Error).self) {
            try CompatibilityCheckOptions.parse(["--metamodel", "library=a.ecore", "--target-metamodel", value])
        }
    }

    @Test("rejects a target metamodel whose name no metamodel has")
    func rejectsUnmatchedTarget() {
        #expect(throws: (any Error).self) {
            try CompatibilityCheckOptions.parse(["--metamodel", "library=a.ecore", "--target-metamodel", "shop=b.ecore"])
        }
    }

    @Test("rejects renamings that are not given as required=provided", arguments: ["Writer", "Writer=", "=Author"])
    func rejectsMalformedRenamings(value: String) {
        #expect(throws: (any Error).self) { try CompatibilityCheckOptions.parse(arguments(["--rename", value])) }
    }

    @Test("accepts a single metamodel and rejects several where only one is supported")
    func singleMetamodel() throws {
        try CompatibilityCheckOptions.parse(arguments()).validateSingleMetamodel()
        let several = try CompatibilityCheckOptions.parse(arguments(["--metamodel", "shop=c.ecore"]))
        #expect(throws: ValidationError.self) { try several.validateSingleMetamodel() }
    }

    // MARK: - Loading

    @Test("loads the metamodels and checks an unchanged one against itself")
    func loadsMetamodels() async throws {
        let files = try LibraryMetamodel.write()
        let options = try CompatibilityCheckOptions.parse([
            "--metamodel", "library=\(files.original)", "--metamodel", "revised=\(files.revised)",
            "--target-metamodel", "library=\(files.revised)",
        ])
        let metamodels = try await options.loadMetamodels()
        #expect(Set(metamodels.required.keys) == ["library", "revised"])
        #expect(metamodels.required["library"]?.objectTypes["Library"]?.property(named: "books") != nil)
        #expect(metamodels.provided["library"]?.objectTypes["Library"]?.property(named: "volumes") != nil)
        #expect(metamodels.provided["revised"] == metamodels.required["revised"])
        #expect(metamodels.sole == nil)
    }

    @Test("reports a metamodel file that does not exist")
    func missingMetamodel() async throws {
        let options = try CompatibilityCheckOptions.parse(arguments())
        await #expect(throws: (any Error).self) { try await options.loadMetamodels() }
    }

    // MARK: - Verdicts and output

    @Test("turns reports into verdicts with distinct exit statuses")
    func verdicts() async throws {
        let options = try libraryOptions()
        let compatible = try await check("self.books->collect(b | b.title)", try libraryOptions(["--rename", "Library.books=volumes"]))
        #expect(CompatibilityVerdict(compatible) == .compatible)
        let incompatible = try await check("self.books->collect(b | b.title)", options)
        #expect(CompatibilityVerdict(incompatible) == .incompatible)
        let inconclusive = try await check("self.eContainer().name", options)
        #expect(CompatibilityVerdict(inconclusive) == .inconclusive)
        #expect(CompatibilityVerdict.allCases.map(\.exitStatus) == [0, 1, 2])
        #expect(CompatibilityVerdict.failureExitStatus == 3)
        #expect(Set(CompatibilityVerdict.allCases.map(\.exitStatus) + [CompatibilityVerdict.failureExitStatus]).count == 4)
    }

    @Test("an incompatible verdict outweighs an incomplete footprint")
    func incompatibleAndInconclusive() async throws {
        let report = try await check("self.books.title->union(self.eContainer().name)", try libraryOptions())
        #expect(!report.compatible)
        #expect(!report.isConclusive)
        #expect(CompatibilityVerdict(report) == .incompatible)
    }

    @Test("widens numeric types and relaxes lower bounds only when asked")
    func wideningAndLeniency() async throws {
        let narrowedRead = "self.volumes->collect(b | b.pages)"
        let back = ["--rename", "Library.volumes=books"]
        #expect(!(try await check(narrowedRead, try libraryOptions(back, reversed: true))).compatible)
        #expect(try await check(narrowedRead, try libraryOptions(back + ["--allow-widening"], reversed: true)).compatible)
        let widenedRead = "self.books->collect(b | b.pages)"
        let renamed = ["--rename", "Library.books=volumes", "--allow-widening"]
        #expect(!(try await check(widenedRead, try libraryOptions(renamed))).compatible)
        let name = "self.name"
        #expect(!(try await check(name, try libraryOptions())).compatible)
        let lenient = try await check(name, try libraryOptions(["--lenient-lower-bounds"]))
        #expect(lenient.compatible)
        #expect(lenient.warnings.contains { $0.code == .multiplicityMismatch })
    }

    @Test("renders a report as text")
    func textOutput() async throws {
        let options = try libraryOptions()
        let report = try await check("self.books->collect(b | b.title)", options)
        let text = try options.render(report)
        #expect(text == report.formatted())
        #expect(text.hasPrefix("incompatible (partial): 1 error(s)"))
        #expect(text.contains("hint: --rename Library.books=volumes"))
    }

    @Test("renders a report as JSON with its verdict, decodable as the report")
    func jsonOutput() async throws {
        let options = try libraryOptions(["--format", "json"])
        let report = try await check("self.eContainer().name", options)
        let json = try options.render(report)
        let object = try #require(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        #expect(object[CompatibilityReportDocument.FlagKey.compatible.rawValue] as? Bool == true)
        #expect(object[CompatibilityReportDocument.FlagKey.conclusive.rawValue] as? Bool == false)
        #expect(object["mode"] as? String == SubtypingMode.partial.rawValue)
        #expect(try JSONDecoder().decode(CompatibilityReport.self, from: Data(json.utf8)) == report)
        #expect(!json.contains("\\/"))
    }

    @Test("writes the features of the footprint as objects with readable access")
    func jsonFootprint() async throws {
        let options = try libraryOptions(["--format", "json"])
        let report = try await check("self.books->collect(b | b.title)", options)
        let json = try options.render(report)
        let object = try #require(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let footprint = try #require(object["footprint"] as? [String: Any])
        let metamodels = try #require(footprint["metamodels"] as? [String: Any])
        let library = try #require(metamodels["library"] as? [String: Any])
        let features = try #require(library["features"] as? [[String: Any]])
        let title = try #require(features.first { $0["featureName"] as? String == "title" })
        #expect(title["className"] as? String == "Book")
        #expect(title["access"] as? [String] == ["read"])
        #expect(title["isCertain"] as? Bool == true)
        #expect(features.map { $0["featureName"] as? String ?? "" } == ["title", "books"])
        #expect(!json.contains("\"access\" : 1"))
    }

    @Test("warns of options that the mode or the semantics ignores")
    func ignoredOptions() throws {
        let rename = ["--rename", "Library.books=volumes"]
        let warning = CompatibilityCheckOptions.warningPrefix
        for mode in ["partial-isomorphic", "total-isomorphic"] {
            let warnings = try CompatibilityCheckOptions.parse(arguments(rename + ["--mode", mode])).ignoredOptionWarnings
            #expect(warnings == [warning + "--rename is ignored in the mode \(mode), which admits no renaming"])
        }
        for mode in ["partial", "total-non-isomorphic"] {
            #expect(try CompatibilityCheckOptions.parse(arguments(rename + ["--mode", mode])).ignoredOptionWarnings.isEmpty)
        }
        #expect(try CompatibilityCheckOptions.parse(arguments()).ignoredOptionWarnings.isEmpty)
        let isomorphic = try CompatibilityCheckOptions.parse(
            arguments(["--mode", "partial-isomorphic", "--allow-widening", "--lenient-lower-bounds"]))
        #expect(isomorphic.ignoredOptionWarnings == [
            warning + "--allow-widening is ignored in the mode partial-isomorphic, which admits no adaptation",
            warning + "--lenient-lower-bounds is ignored in the mode partial-isomorphic, which admits no adaptation",
        ])
        let published = try CompatibilityCheckOptions.parse(
            arguments(["--subtyping", "object-type-matching", "--allow-widening", "--lenient-lower-bounds"]))
        #expect(published.ignoredOptionWarnings == [
            warning + "--allow-widening is ignored by object-type-matching; it applies only to the access-refined semantics",
            warning + "--lenient-lower-bounds is ignored by object-type-matching; it applies only to the access-refined semantics",
        ])
        let refined = try CompatibilityCheckOptions.parse(arguments(["--allow-widening", "--lenient-lower-bounds"]))
        #expect(refined.ignoredOptionWarnings.isEmpty)
    }

    @Test("describes the command, its statuses and the option of the matching semantics")
    func discussion() {
        let text = CompatibilityCheckOptions.discussion(module: "the transformation")
        #expect(text.contains("the transformation"))
        for status in ["0", "1", "2", "3", "64"] { #expect(text.contains(status)) }
        #expect(text.contains("--subtyping"))
        #expect(!text.contains("--semantics"))
        #expect(!text.contains("\u{2014}"))
    }
}
