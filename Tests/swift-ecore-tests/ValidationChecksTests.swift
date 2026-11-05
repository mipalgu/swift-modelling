import Foundation
import Testing

/// Runs the validate command.
///
/// - Parameters:
///   - model: The model or metamodel resource to validate, as `subdirectory/name`.
///   - metamodel: The metamodel resource, as `subdirectory/name`, if any.
///   - options: Further arguments.
/// - Returns: The result of the command.
@MainActor
private func validate(_ model: String, metamodel: String? = nil, _ options: [String] = []) async throws -> SubprocessResult {
    func resource(_ path: String) throws -> String {
        let parts = path.split(separator: "/").map(String.init)
        return try loadTestResource(named: parts[1], subdirectory: parts[0]).path
    }
    var arguments = [try resource(model)]
    if let metamodel { arguments += ["--metamodel", try resource(metamodel)] }
    return try await executeSwiftEcore(command: "validate", arguments: arguments + options)
}

@Suite("swift-ecore validate - Metamodel checks")
struct ValidateMetamodelChecksTests {
    @Test("reports a violated Ecore constraint with the element that violates it")
    @MainActor
    func inconsistentBounds() async throws {
        let result = try await validate("ecore/bounds.ecore")

        #expect(!result.succeeded)
        #expect(result.stdout.contains("error: //Box/label: The lower bound 2 must not exceed the upper bound 1."))
        #expect(result.stderr.contains("Validation failed: 1 error(s), 0 warning(s)"))
    }

    @Test("lists abstract classes with their concrete subclasses")
    @MainActor
    func abstractClasses() async throws {
        let result = try await validate("ecore/classifiers.ecore", ["--check-abstract-classes"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(
            result.stdout == """
                Abstract classes and interfaces: 2
                  NamedElement (abstract): concrete subclasses Package, DataType, Class, Attribute
                  Classifier (abstract): concrete subclasses DataType, Class
                Validation completed successfully

                """)
    }

    @Test("warns about an abstract class that no concrete class extends, and fails on it in strict mode")
    @MainActor
    func abstractWithoutSubclass() async throws {
        let lenient = try await validate("ecore/staff.ecore", ["--check-abstract-classes"])
        let strict = try await validate("ecore/staff.ecore", ["--check-abstract-classes", "--strict"])

        #expect(lenient.succeeded, "\(lenient.stdout)\(lenient.stderr)")
        #expect(lenient.stdout.contains("  Contact (abstract): no concrete subclass\n"))
        #expect(lenient.stdout.contains("warning: Contact (//Contact): No concrete class extends Contact"))
        #expect(!strict.succeeded)
        #expect(strict.stderr.contains("0 error(s), 1 warning(s) (strict: warnings count as errors)"))
    }
}

@Suite("swift-ecore validate - Model checks")
struct ValidateModelChecksTests {
    @Test("accepts a model that conforms to its metamodel")
    @MainActor
    func conforming() async throws {
        let result = try await validate("xmi/staff.xmi", metamodel: "ecore/staff.ecore", ["--check-abstract-classes"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("information: No object is an instance of an abstract class or an interface"))
        #expect(result.stdout.hasSuffix("Validation completed successfully\n"))
    }

    @Test("rejects an object of an abstract class")
    @MainActor
    func abstractInstance() async throws {
        let result = try await validate("xmi/staff-abstract.xmi", metamodel: "ecore/staff.ecore")

        #expect(!result.succeeded)
        #expect(result.stdout.contains("error: Person 'Nobody' (//@staff.0): Class Person is abstract and cannot be instantiated"))
    }

    @Test("rejects a feature that the class does not define")
    @MainActor
    func undefinedFeature() async throws {
        let result = try await validate("xmi/enterprise-typo.xmi", metamodel: "ecore/enterprise.ecore")

        #expect(!result.succeeded)
        #expect(result.stdout.contains("error: Department (//@departments.0): Class Department defines no feature 'nmae'"))
    }

    @Test("warns that abstract classes cannot be checked without a metamodel")
    @MainActor
    func abstractWithoutMetamodel() async throws {
        let result = try await validate("xmi/staff.xmi", ["--check-abstract-classes"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("warning: Without a metamodel, it is unknown which classes are abstract"))
    }

    @Test("resolves a reference into another document")
    @MainActor
    func crossDocumentReference() async throws {
        let result = try await validate("xmi/enterprise-project.xmi", metamodel: "ecore/enterprise.ecore")

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
    }

    @Test("rejects a reference into another document that names no object")
    @MainActor
    func danglingReference() async throws {
        let result = try await validate("xmi/enterprise-dangling.xmi", metamodel: "ecore/enterprise.ecore")

        #expect(!result.succeeded)
        #expect(
            result.stdout.contains(
                "error: Department 'Projects' (/): Reference 'partners' names enterprise-shared.xmi#/5, which does not exist"))
    }
}

@Suite("swift-ecore validate - OCL invariants")
struct ValidateInvariantTests {
    @Test("evaluates every invariant for every object it applies to")
    @MainActor
    func satisfied() async throws {
        let quiet = try await validate("xmi/ledger-valid.xmi", metamodel: "ecore/ledger.ecore")
        let verbose = try await validate("xmi/ledger-valid.xmi", metamodel: "ecore/ledger.ecore", ["--verbose"])

        #expect(quiet.succeeded, "\(quiet.stdout)\(quiet.stderr)")
        #expect(quiet.stdout == "OCL invariants: 7 of 7 check(s) satisfied\nValidation completed successfully\n")
        #expect(verbose.stdout.contains("Checking constraint: uniqueNumbers (Ledger, /) ... satisfied"))
        #expect(verbose.stdout.contains("Checking constraint: debitsAreSmall (Entry '2', //@entries.1) ... satisfied"))
    }

    @Test("reports each violated invariant with the object that violates it")
    @MainActor
    func violated() async throws {
        let result = try await validate("xmi/ledger-invalid.xmi", metamodel: "ecore/ledger.ecore")

        #expect(!result.succeeded)
        #expect(
            result.stdout == """
                Checking constraint: uniqueNumbers (Ledger, /) ... violated
                Checking constraint: positiveAmount (Entry '1', //@entries.0) ... violated
                Checking constraint: namedPayee (Entry '1', //@entries.1) ... violated
                Checking constraint: debitsAreSmall (Entry '1', //@entries.1) ... violated
                OCL invariants: 3 of 7 check(s) satisfied

                """)
        #expect(result.stderr.contains("Validation failed: 4 error(s), 0 warning(s)"))
    }

    @Test("writes a JSON report with the findings and the evaluations")
    @MainActor
    func jsonReport() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let file = directory.appendingPathComponent("report.json")

        let result = try await validate(
            "xmi/ledger-invalid.xmi", metamodel: "ecore/ledger.ecore", ["--format", "json", "--report", file.path])

        #expect(!result.succeeded)
        #expect(result.stdout.contains("Validation report written: \(file.path)"))
        let json = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        #expect(json["valid"] as? Bool == false)
        #expect(json["errors"] as? Int == 4)
        let findings = try #require(json["findings"] as? [[String: Any]])
        #expect(findings.first?["code"] as? String == "ocl.invariant")
        #expect(findings.first?["location"] as? String == "/")
        let constraints = try #require(json["constraints"] as? [[String: Any]])
        #expect(constraints.count == 7)
    }

    @Test("prints only JSON on standard output for a valid model")
    @MainActor
    func jsonOnStandardOutput() async throws {
        let result = try await validate("xmi/ledger-valid.xmi", metamodel: "ecore/ledger.ecore", ["--format", "json"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let json = try #require(try JSONSerialization.jsonObject(with: Data(result.stdout.utf8)) as? [String: Any])
        #expect(json["valid"] as? Bool == true)
        #expect(json["kind"] as? String == "model")
    }
}

@Suite("swift-ecore validate - Multiplicities")
struct ValidateMultiplicityTests {
    /// The metamodel of the shelf models.
    private static let metamodel = "ecore/shelf.ecore"

    @Test("counts the one child of a required many-valued containment and every other single value")
    @MainActor
    func singleValues() async throws {
        let result = try await validate("xmi/shelf-single.xmi", metamodel: Self.metamodel)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout == "Validation completed successfully\n")
    }

    /// The flag that makes every required single-valued feature need a value of its own.
    private static let requireExplicitValues = "--require-explicit-values"

    @Test("accepts unset required attributes that read as defaults, as the Eclipse Modeling Framework does")
    @MainActor
    func unsetAttributes() async throws {
        let result = try await validate("xmi/shelf-unset.xmi", metamodel: Self.metamodel)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout == "Validation completed successfully\n")
    }

    @Test("reports required attributes that are unset, whatever the default of their type, with --require-explicit-values")
    @MainActor
    func unsetAttributesRequiringExplicitValues() async throws {
        let result = try await validate(
            "xmi/shelf-unset.xmi", metamodel: Self.metamodel, [Self.requireExplicitValues])

        #expect(!result.succeeded)
        #expect(
            result.stdout == """
                error: Book 'Emma' (//@books.0): Feature 'kind' needs at least 1 value(s) but has 0
                error: Book 'Emma' (//@books.0): Feature 'pages' needs at least 1 value(s) but has 0

                """)
        #expect(result.stderr.contains("Validation failed: 2 error(s), 0 warning(s)"))
    }

    @Test("reports an unset required attribute without a default in either mode", arguments: [[], [requireExplicitValues]])
    @MainActor
    func unsetAttributeWithoutDefault(options: [String]) async throws {
        let result = try await validate("xmi/shelf-untitled.xmi", metamodel: Self.metamodel, options)

        #expect(!result.succeeded)
        #expect(
            result.stdout == """
                error: Book (//@books.0): Feature 'title' needs at least 1 value(s) but has 0

                """)
        #expect(result.stderr.contains("Validation failed: 1 error(s), 0 warning(s)"))
    }

    @Test("does not confuse --require-explicit-values with --strict")
    @MainActor
    func strictIsNotExplicit() async throws {
        let result = try await validate("xmi/shelf-unset.xmi", metamodel: Self.metamodel, ["--strict"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
    }

    @Test("lists --require-explicit-values in the help and explains how it differs from Eclipse")
    @MainActor
    func help() async throws {
        let result = try await executeSwiftEcore(command: "validate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.requireExplicitValues))
        #expect(result.stdout.contains("Eclipse Modeling Framework"))
    }

    @Test("reports every kind of required feature without values, in feature order")
    @MainActor
    func emptyFeatures() async throws {
        let result = try await validate("xmi/shelf-empty.xmi", metamodel: Self.metamodel)

        #expect(!result.succeeded)
        #expect(
            result.stdout == """
                error: Shelf (/): Feature 'books' needs at least 1 value(s) but has 0
                error: Shelf (/): Feature 'sign' needs at least 1 value(s) but has 0
                error: Shelf (/): Feature 'favourite' needs at least 1 value(s) but has 0
                error: Shelf (/): Feature 'picks' needs at least 1 value(s) but has 0
                error: Shelf (/): Feature 'tags' needs at least 1 value(s) but has 0

                """)
    }

    @Test("reports many-valued references and attributes with more values than allowed")
    @MainActor
    func upperBounds() async throws {
        let result = try await validate("xmi/shelf-crowded.xmi", metamodel: Self.metamodel)

        #expect(!result.succeeded)
        #expect(
            result.stdout == """
                error: Shelf (/): Feature 'picks' allows at most 2 value(s) but has 3
                error: Shelf (/): Feature 'tags' allows at most 2 value(s) but has 3

                """)
    }

    @Test("checks every file of a batch with the same counts")
    @MainActor
    func batch() async throws {
        let paths = try ["shelf-single.xmi", "shelf-unset.xmi"].map {
            try loadTestResource(named: $0, subdirectory: "xmi").path
        }
        let metamodel = try loadTestResource(named: "shelf.ecore", subdirectory: "ecore").path
        let result = try await executeSwiftEcore(
            command: "validate", arguments: paths + ["--metamodel", metamodel, Self.requireExplicitValues])

        #expect(!result.succeeded)
        #expect(!result.stdout.contains("'books'"), "\(result.stdout)")
        #expect(result.stdout.contains("Feature 'kind' needs at least 1 value(s) but has 0"), "\(result.stdout)")
    }
}

@Suite("swift-ecore validate - Strict AQL")
struct ValidateStrictAQLTests {
    /// A metamodel whose only class has an invariant that concatenates a single value to a sequence.
    private static let metamodel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="notes"
            nsURI="http://www.example.org/notes" nsPrefix="notes">
          <eClassifiers xsi:type="ecore:EClass" name="Note">
            <eAnnotations source="http://www.eclipse.org/emf/2002/Ecore/OCL">
              <details key="twoWords" value="Sequence{'a'}->concat('b')->size() = 2"/>
            </eAnnotations>
          </eClassifiers>
        </ecore:EPackage>
        """

    /// A model with one note.
    private static let model = """
        <?xml version="1.0" encoding="UTF-8"?>
        <notes:Note xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:notes="http://www.example.org/notes"/>
        """

    /// Validates the note model with extra arguments.
    private func validate(_ extra: [String]) async throws -> SubprocessResult {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let metamodel = directory.appendingPathComponent("notes.ecore")
        let model = directory.appendingPathComponent("note.xmi")
        try Self.metamodel.write(to: metamodel, atomically: true, encoding: .utf8)
        try Self.model.write(to: model, atomically: true, encoding: .utf8)
        return try await executeSwiftEcore(
            command: "validate", arguments: [model.path, "--metamodel", metamodel.path] + extra)
    }

    @Test("accepts an invariant that passes a single value to concat by default")
    @MainActor
    func lenient() async throws {
        let result = try await validate([])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("OCL invariants: 1 of 1 check(s) satisfied"))
    }

    @Test("reports the invariant as an error with --strict-aql, unlike --strict")
    @MainActor
    func strict() async throws {
        let strictAQL = try await validate(["--strict-aql"])
        let strictWarnings = try await validate(["--strict"])

        #expect(!strictAQL.succeeded, "\(strictAQL.stdout)")
        #expect(strictAQL.stdout.contains("twoWords"), "\(strictAQL.stdout)")
        #expect(strictWarnings.succeeded, "\(strictWarnings.stdout)\(strictWarnings.stderr)")
    }
}
