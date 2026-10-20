import Testing
import Foundation

/// Test suite for ATL Advanced Tutorial 01: Class to Relational
/// Validates the classic Class2Relational transformation benchmark
@Suite("Advanced Tutorial: Class2Relational Transformation")
struct ATLAdvanced01Tests {

    static let tutorialCodePath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")
        .appendingPathComponent("Code")
        .appendingPathComponent("ATL-Advanced-01")

    // MARK: - Section 1: CLI Validation of Metamodels

    @Test("CLI: Validate Class metamodel via swift-ecore")
    @MainActor
    func testCLIValidateClassMetamodel() async throws {
        let classEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class.ecore")

        #expect(FileManager.default.fileExists(atPath: classEcorePath.path), "Class metamodel should exist")

        // Use swift-ecore validate to ensure the metamodel can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [classEcorePath.path]
        )

        #expect(result.succeeded, "Class metamodel should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate Relational metamodel via swift-ecore")
    @MainActor
    func testCLIValidateRelationalMetamodel() async throws {
        let relationalEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("relational.ecore")

        #expect(FileManager.default.fileExists(atPath: relationalEcorePath.path), "Relational metamodel should exist")

        // Use swift-ecore validate to ensure the metamodel can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [relationalEcorePath.path]
        )

        #expect(result.succeeded, "Relational metamodel should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate sample input model via swift-ecore")
    @MainActor
    func testCLIValidateSampleInput() async throws {
        let samplePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("sample-classes.xmi")

        #expect(FileManager.default.fileExists(atPath: samplePath.path), "Sample classes model should exist")

        // Use swift-ecore validate to ensure the model can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [samplePath.path]
        )

        #expect(result.succeeded, "Sample classes model should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate expected output model via swift-ecore")
    @MainActor
    func testCLIValidateExpectedOutput() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")

        #expect(FileManager.default.fileExists(atPath: outputPath.path), "Expected output should exist")

        // Use swift-ecore validate to ensure the model can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [outputPath.path]
        )

        #expect(result.succeeded, "Expected output should validate successfully: \(result.stderr)")
    }

    // MARK: - Section 2: Validate Source Metamodel (Class) Content

    @Test("Content: Validate Class metamodel structure")
    func testStep01ValidateClassMetamodel() async throws {
        let classEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class.ecore")

        let content = try String(contentsOf: classEcorePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("ecore:EPackage"))
        #expect(content.contains("name=\"Class\""))
        #expect(content.contains("nsURI=\"http://www.example.org/class\""))

        // Verify key classes exist
        #expect(content.contains("name=\"Package\""))
        #expect(content.contains("name=\"Class\""))
        #expect(content.contains("name=\"Attribute\""))
        #expect(content.contains("name=\"DataType\""))
        #expect(content.contains("name=\"Classifier\""))
        #expect(content.contains("name=\"NamedElement\""))
    }

    @Test("Content: Validate Class metamodel features")
    func testStep02ValidateClassFeatures() async throws {
        let classEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class.ecore")
        let content = try String(contentsOf: classEcorePath, encoding: .utf8)

        // Verify Package contains classifiers
        #expect(content.contains("name=\"classifiers\""))

        // Verify Class has key features
        #expect(content.contains("name=\"isAbstract\""))
        #expect(content.contains("name=\"superType\""))
        #expect(content.contains("name=\"attributes\""))

        // Verify Attribute has key features
        #expect(content.contains("name=\"multiValued\""))
        #expect(content.contains("name=\"type\""))
        #expect(content.contains("name=\"owner\""))
    }

    // MARK: - Section 3: Validate Target Metamodel (Relational) Content

    @Test("Content: Validate Relational metamodel structure")
    func testStep03ValidateRelationalMetamodel() async throws {
        let relationalEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("relational.ecore")

        let content = try String(contentsOf: relationalEcorePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("ecore:EPackage"))
        #expect(content.contains("name=\"Relational\""))
        #expect(content.contains("nsURI=\"http://www.example.org/relational\""))

        // Verify key classes exist
        #expect(content.contains("name=\"Schema\""))
        #expect(content.contains("name=\"Table\""))
        #expect(content.contains("name=\"Column\""))
        #expect(content.contains("name=\"Type\""))
    }

    @Test("Content: Validate Relational metamodel features")
    func testStep04ValidateRelationalFeatures() async throws {
        let relationalEcorePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("relational.ecore")
        let content = try String(contentsOf: relationalEcorePath, encoding: .utf8)

        // Verify Schema contains tables and types
        #expect(content.contains("name=\"tables\""))
        #expect(content.contains("name=\"types\""))

        // Verify Table has key features
        #expect(content.contains("name=\"columns\""))
        #expect(content.contains("name=\"key\""))
        #expect(content.contains("name=\"schema\""))

        // Verify Column has type reference
        #expect(content.contains("name=\"keyOf\""))
    }

    // MARK: - Section 4: Validate ATL Transformation

    @Test("ATL: Validate transformation module declaration")
    func testStep05ValidateModuleDeclaration() async throws {
        let atlPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class2relational.atl")

        #expect(FileManager.default.fileExists(atPath: atlPath.path))

        let content = try String(contentsOf: atlPath, encoding: .utf8)

        // Verify module declaration
        #expect(content.contains("module Class2Relational"))
        #expect(content.contains("create OUT: Relational from IN: Class"))
    }

    @Test("ATL: Validate helper functions")
    func testStep06ValidateHelpers() async throws {
        let atlPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class2relational.atl")
        let content = try String(contentsOf: atlPath, encoding: .utf8)

        // Verify allAttributes helper
        #expect(content.contains("helper context Class!Class def: allAttributes"))
        #expect(content.contains("superType"))

        // Verify isDataType helper
        #expect(content.contains("helper context Class!Classifier def: isDataType"))
        #expect(content.contains("oclIsTypeOf"))

        // Verify sqlTypeName helper
        #expect(content.contains("helper context Class!DataType def: sqlTypeName"))
        #expect(content.contains("INTEGER"))
        #expect(content.contains("VARCHAR"))
        #expect(content.contains("BOOLEAN"))
    }

    @Test("ATL: Validate Package2Schema rule")
    func testStep07ValidatePackage2SchemaRule() async throws {
        let atlPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class2relational.atl")
        let content = try String(contentsOf: atlPath, encoding: .utf8)

        #expect(content.contains("rule Package2Schema"))
        #expect(content.contains("p: Class!Package"))
        #expect(content.contains("s: Relational!Schema"))
        #expect(content.contains("name <- p.name"))
        #expect(content.contains("tables <-"))
        #expect(content.contains("types <-"))
    }

    @Test("ATL: Validate Class2Table rule")
    func testStep08ValidateClass2TableRule() async throws {
        let atlPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class2relational.atl")
        let content = try String(contentsOf: atlPath, encoding: .utf8)

        #expect(content.contains("rule Class2Table"))
        #expect(content.contains("c: Class!Class"))
        #expect(content.contains("not c.isAbstract"))
        #expect(content.contains("t: Relational!Table"))
        #expect(content.contains("key: Relational!Column"))
        #expect(content.contains("name <- 'id'"))
        #expect(content.contains("keyOf <- t"))
    }

    @Test("ATL: Validate attribute transformation rules")
    func testStep09ValidateAttributeRules() async throws {
        let atlPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("class2relational.atl")
        let content = try String(contentsOf: atlPath, encoding: .utf8)

        // SingleValuedAttribute2Column rule
        #expect(content.contains("rule SingleValuedAttribute2Column"))
        #expect(content.contains("not a.multiValued"))
        #expect(content.contains("c: Relational!Column"))

        // MultiValuedAttribute2Table rule
        #expect(content.contains("rule MultiValuedAttribute2Table"))
        #expect(content.contains("a.multiValued"))
        #expect(content.contains("t: Relational!Table"))

        // ClassAttribute2ForeignKey rule
        #expect(content.contains("rule ClassAttribute2ForeignKey"))
        #expect(content.contains("fk: Relational!Column"))
        #expect(content.contains("_id"))
    }

    // MARK: - Section 5: Validate Sample Input Model Content

    @Test("Content: Validate sample classes model")
    func testStep10ValidateSampleInput() async throws {
        let samplePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("sample-classes.xmi")

        let content = try String(contentsOf: samplePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("xmi:XMI"))
        #expect(content.contains("class:Package"))
        #expect(content.contains("name=\"library\""))

        // Verify data types
        #expect(content.contains("name=\"Integer\""))
        #expect(content.contains("name=\"String\""))
        #expect(content.contains("name=\"Boolean\""))
        #expect(content.contains("name=\"Date\""))

        // Verify classes
        #expect(content.contains("name=\"Author\""))
        #expect(content.contains("name=\"Book\""))
        #expect(content.contains("name=\"Member\""))
        #expect(content.contains("name=\"Loan\""))
    }

    @Test("Content: Validate sample model attributes")
    func testStep11ValidateSampleAttributes() async throws {
        let samplePath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("sample-classes.xmi")
        let content = try String(contentsOf: samplePath, encoding: .utf8)

        // Verify Author attributes
        #expect(content.contains("name=\"firstName\""))
        #expect(content.contains("name=\"lastName\""))
        #expect(content.contains("name=\"birthYear\""))

        // Verify Book attributes (including multi-valued)
        #expect(content.contains("name=\"title\""))
        #expect(content.contains("name=\"isbn\""))
        #expect(content.contains("name=\"keywords\" multiValued=\"true\""))

        // Verify Member attributes
        #expect(content.contains("name=\"memberNumber\""))
        #expect(content.contains("name=\"email\""))
        #expect(content.contains("name=\"borrowedBooks\" multiValued=\"true\""))
    }

    // MARK: - Section 6: Validate Expected Output Content

    @Test("Content: Validate expected output schema")
    func testStep12ValidateExpectedOutput() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")

        let content = try String(contentsOf: outputPath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("xmi:XMI"))
        #expect(content.contains("relational:Schema"))
        #expect(content.contains("name=\"library\""))

        // Verify SQL types created
        #expect(content.contains("name=\"INTEGER\""))
        #expect(content.contains("name=\"VARCHAR(255)\""))
        #expect(content.contains("name=\"BOOLEAN\""))
        #expect(content.contains("name=\"DATE\""))
    }

    @Test("Content: Validate expected tables")
    func testStep13ValidateExpectedTables() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")
        let content = try String(contentsOf: outputPath, encoding: .utf8)

        // Verify main tables created from classes
        #expect(content.contains("<tables name=\"Author\""))
        #expect(content.contains("<tables name=\"Book\""))
        #expect(content.contains("<tables name=\"Member\""))
        #expect(content.contains("<tables name=\"Loan\""))

        // Verify multi-valued attribute tables
        #expect(content.contains("<tables name=\"Book_keywords\""))
        #expect(content.contains("<tables name=\"Member_borrowedBooks\""))
    }

    @Test("Content: Validate primary keys")
    func testStep14ValidatePrimaryKeys() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")
        let content = try String(contentsOf: outputPath, encoding: .utf8)

        // Verify id columns exist as primary keys
        #expect(content.contains("<columns name=\"id\""))
        #expect(content.contains("keyOf="))

        // Count id columns (should be 4 - one for each main table)
        let idColumns = content.components(separatedBy: "<columns name=\"id\"").count - 1
        #expect(idColumns >= 4, "Expected at least 4 primary key columns")
    }

    @Test("Content: Validate foreign keys")
    func testStep15ValidateForeignKeys() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")
        let content = try String(contentsOf: outputPath, encoding: .utf8)

        // Verify foreign key columns for class-typed attributes
        #expect(content.contains("name=\"author_id\""))
        #expect(content.contains("name=\"book_id\""))
        #expect(content.contains("name=\"member_id\""))
    }

    @Test("Content: Validate multi-valued attribute tables")
    func testStep16ValidateMultiValuedTables() async throws {
        let outputPath = ATLAdvanced01Tests.tutorialCodePath.appendingPathComponent("expected-output.xmi")
        let content = try String(contentsOf: outputPath, encoding: .utf8)

        // Book_keywords table should have book_id and keywords columns
        #expect(content.contains("<tables name=\"Book_keywords\""))

        // Member_borrowedBooks table should have member_id and borrowedBooks columns
        #expect(content.contains("<tables name=\"Member_borrowedBooks\""))
    }

    // MARK: - Section 7: Transformation Parsing and Execution

    /// A relational schema reduced to what the tutorial compares: the type names and, for each table,
    /// its columns with their type names and whether they are a primary key.
    struct SchemaSummary: Equatable {
        struct Column: Equatable {
            let name: String
            let typeName: String
            let isKey: Bool
        }
        struct Table: Equatable {
            let name: String
            let columns: [Column]
        }
        let schemaName: String
        let typeNames: [String]
        let tables: [Table]
    }

    /// Summarises a relational model, whether the columns record their type and primary key as attributes
    /// (the tutorial's expected output) or as child elements (the output of swift-atl).
    static func summary(of xml: String) -> SchemaSummary {
        func attribute(_ name: String, in line: String) -> String? {
            guard let start = line.range(of: " \(name)=\"") else { return nil }
            let rest = line[start.upperBound...]
            return rest.firstIndex(of: "\"").map { String(rest[..<$0]) }
        }
        func typeIndex(_ reference: String) -> Int? {
            reference.range(of: "@types.").flatMap { Int(reference[$0.upperBound...]) }
        }
        var schemaName = ""
        var typeNames: [String] = []
        var tables: [(name: String, columns: [(name: String, type: Int, isKey: Bool)])] = []
        var column: (name: String, type: Int, isKey: Bool)?
        func finishColumn() {
            if let finished = column, !tables.isEmpty { tables[tables.count - 1].columns.append(finished) }
            column = nil
        }
        for line in xml.split(whereSeparator: \.isNewline).map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if line.contains(":Schema "), let name = attribute("name", in: line) {
                schemaName = name
            } else if line.hasPrefix("<types "), let name = attribute("name", in: line) {
                typeNames.append(name)
            } else if line.hasPrefix("<tables "), let name = attribute("name", in: line) {
                finishColumn()
                tables.append((name: name, columns: []))
            } else if line.hasPrefix("<columns "), let name = attribute("name", in: line) {
                finishColumn()
                let type = attribute("type", in: line).flatMap(typeIndex) ?? -1
                column = (name: name, type: type, isKey: attribute("keyOf", in: line) != nil)
                if line.hasSuffix("/>") { finishColumn() }
            } else if line.hasPrefix("<type "), let reference = attribute("href", in: line) {
                column?.type = typeIndex(reference) ?? -1
            } else if line.hasPrefix("<keyOf ") {
                column?.isKey = true
            } else if line == "</columns>" {
                finishColumn()
            }
        }
        finishColumn()
        return SchemaSummary(
            schemaName: schemaName,
            typeNames: typeNames,
            tables: tables.map { table in
                SchemaSummary.Table(
                    name: table.name,
                    columns: table.columns.map { column in
                        SchemaSummary.Column(
                            name: column.name,
                            typeName: typeNames.indices.contains(column.type) ? typeNames[column.type] : "",
                            isKey: column.isKey)
                    })
            })
    }

    @Test("CLI: Parse the transformation via swift-atl")
    @MainActor
    func testCLIParseTransformation() async throws {
        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl",
            arguments: ["parse", Self.tutorialCodePath.appendingPathComponent("class2relational.atl").path])
        #expect(result.succeeded, "The transformation should parse: \(result.stdout)\(result.stderr)")
    }

    @Test("CLI: Validate the transformation via swift-atl")
    @MainActor
    func testCLIValidateTransformation() async throws {
        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl",
            arguments: ["validate", Self.tutorialCodePath.appendingPathComponent("class2relational.atl").path])
        #expect(result.succeeded, "The transformation should validate: \(result.stdout)\(result.stderr)")
    }

    @Test("ATL: The metamodel directives are relative to the transformation")
    func testMetamodelDirectives() throws {
        let content = try String(
            contentsOf: Self.tutorialCodePath.appendingPathComponent("class2relational.atl"), encoding: .utf8)
        #expect(content.contains("-- @path Class=class.ecore"))
        #expect(content.contains("-- @path Relational=relational.ecore"))
        #expect(!content.contains("/Class2Relational/"))
    }

    @Test("Content: The expected output summarises to six tables, 25 columns and four types")
    func testExpectedOutputSummary() throws {
        let expected = Self.summary(
            of: try String(
                contentsOf: Self.tutorialCodePath.appendingPathComponent("expected-output.xmi"), encoding: .utf8))
        #expect(expected.schemaName == "library")
        #expect(expected.typeNames == ["INTEGER", "VARCHAR(255)", "BOOLEAN", "DATE"])
        #expect(expected.tables.count == 6)
        #expect(expected.tables.reduce(0) { $0 + $1.columns.count } == 25)
        let loan = try #require(expected.tables.first { $0.name == "Loan" })
        #expect(loan.columns.first == SchemaSummary.Column(name: "id", typeName: "INTEGER", isKey: true))
        #expect(loan.columns.contains(SchemaSummary.Column(name: "book_id", typeName: "INTEGER", isKey: false)))
    }

    @Test("CLI: The transformation produces the expected schema")
    @MainActor
    func testCLITransformMatchesExpectedOutput() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appendingPathComponent("swift-modelling-tutorial-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        for name in ["class.ecore", "relational.ecore", "class2relational.atl", "sample-classes.xmi"] {
            try FileManager.default.copyItem(
                at: Self.tutorialCodePath.appendingPathComponent(name),
                to: workspace.appendingPathComponent(name))
        }

        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl",
            arguments: [
                "transform", "class2relational.atl",
                "--source", "IN=sample-classes.xmi",
                "--target", "OUT=output-relational.xmi",
            ],
            in: workspace)
        #expect(result.succeeded, "The transformation should run: \(result.stdout)\(result.stderr)")

        let actual = Self.summary(
            of: try String(
                contentsOf: workspace.appendingPathComponent("output-relational.xmi"), encoding: .utf8))
        let expected = Self.summary(
            of: try String(
                contentsOf: Self.tutorialCodePath.appendingPathComponent("expected-output.xmi"), encoding: .utf8))
        #expect(actual.tables.count == 6)
        #expect(actual == expected)
    }

    @Test("Script: The run script uses the documented command")
    func testRunScript() throws {
        let content = try String(
            contentsOf: Self.tutorialCodePath.appendingPathComponent("atl-advanced-01-run.sh"), encoding: .utf8)
        #expect(content.contains("swift-atl transform class2relational.atl"))
        #expect(content.contains("--source IN=sample-classes.xmi"))
        #expect(content.contains("--target OUT=output-relational.xmi"))
        #expect(!content.contains("--transformation"))
    }
}
