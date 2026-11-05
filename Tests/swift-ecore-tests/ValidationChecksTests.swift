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
