import Foundation
import Testing

/// Runs the compare command.
///
/// - Parameter arguments: The arguments after the subcommand.
/// - Returns: The result of the command.
@MainActor
private func compare(_ arguments: [String]) async throws -> SubprocessResult {
    try await executeSwiftEcore(command: "compare", arguments: arguments)
}

/// The path of a comparison fixture.
///
/// - Parameter name: The file name within the `compare` resources.
/// - Returns: The path.
private func fixture(_ name: String) throws -> String {
    try loadTestResource(named: name, subdirectory: "compare").path
}

@Suite("swift-ecore compare - Metamodels")
struct CompareMetamodelTests {
    @Test("reports every difference between two versions of a metamodel")
    @MainActor
    func differences() async throws {
        let result = try await compare([try fixture("shop-v1.ecore"), try fixture("shop-v2.ecore")])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let lines = result.stdout.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        #expect(lines.first == "Comparing metamodels: shop-v1.ecore -> shop-v2.ecore")
        let expected = [
            "~ package shop nsURI: http://example.org/shop/1.0 -> http://example.org/shop/2.0",
            "~ literal Status.SHIPPED value: 2 -> 3",
            "+ literal Status.CANCELLED: 4",
            "~ data type Money instance class: java.math.BigDecimal -> java.lang.Double",
            "~ classifier Code kind: data type -> enumeration",
            "~ class NamedElement interface: false -> true",
            "~ reference Shop.featured containment: false -> true",
            "+ reference Shop.products: Product [0..*], containment",
            "~ attribute Customer.email id: false -> true",
            "~ reference Customer.orders opposite: Order.customer -> none",
            "+ attribute Customer.phone: EString [0..1]",
            "~ class Order supertypes: none -> Entity",
            "~ attribute Order.status type: EString -> Status",
            "~ attribute Order.total derived: false -> true",
            "~ attribute Order.total transient: false -> true",
            "~ attribute Order.total read-only: false -> true",
            "- attribute Order.note: EString [0..1]",
            "~ reference Order.customer multiplicity: [0..1] -> [1..1]",
            "~ reference Order.customer opposite: Customer.orders -> none",
            "~ operation Order.computeTotal signature: computeTotal(): EDouble -> computeTotal(includeTax: EBoolean): EDouble",
            "~ feature Item.product kind: attribute -> reference",
            "~ reference Item.product type: EString -> Product",
            "~ reference Item.product multiplicity: [0..1] -> [1..1]",
            "~ attribute Item.quantity default: none -> 1",
            "- class Coupon",
            "+ class Entity: abstract",
            "+ class Product: extends NamedElement",
            "+ package billing: http://example.org/shop/2.0/billing",
        ]
        #expect(Array(lines.dropFirst().prefix(expected.count)) == expected)
        #expect(lines.dropFirst(expected.count + 1).first == "28 differences: 6 added, 2 removed, 20 changed")
    }

    @Test("reports no differences between a metamodel and itself")
    @MainActor
    func identical() async throws {
        let staff = try loadTestResource(named: "staff.ecore", subdirectory: "ecore").path

        let result = try await compare([staff, staff])

        #expect(result.succeeded)
        #expect(result.stdout == "Comparing metamodels: staff.ecore -> staff.ecore\nNo differences\n")
    }

    @Test("leaves out ignored elements and properties")
    @MainActor
    func ignore() async throws {
        let result = try await compare([
            try fixture("shop-v1.ecore"), try fixture("shop-v2.ecore"),
            "--ignore", "Order", "--ignore", "Item.product", "--ignore", "nsURI", "--ignore", "Coupon",
        ])

        #expect(result.succeeded)
        #expect(!result.stdout.contains("attribute Order."))
        #expect(!result.stdout.contains("reference Order."))
        #expect(!result.stdout.contains("operation Order."))
        #expect(!result.stdout.contains("class Order"))
        #expect(!result.stdout.contains("Item.product"))
        #expect(!result.stdout.contains("nsURI"))
        #expect(!result.stdout.contains("Coupon"))
        #expect(result.stdout.contains("~ attribute Item.quantity default: none -> 1\n"))
        #expect(result.stdout.contains("~ reference Customer.orders opposite: Order.customer -> none\n"))
    }

    @Test("counts the elements of both metamodels in a summary")
    @MainActor
    func summary() async throws {
        let result = try await compare([try fixture("shop-v1.ecore"), try fixture("shop-v2.ecore"), "--summary"])

        #expect(result.succeeded)
        #expect(
            result.stdout == """
                Comparing metamodels: shop-v1.ecore -> shop-v2.ecore
                Elements:
                  Packages: 1 -> 2 (+1)
                  Classes: 6 -> 8 (+2)
                  Enumerations: 1 -> 2 (+1)
                  Data types: 2 -> 1 (-1)
                  Attributes: 10 -> 10
                  References: 6 -> 8 (+2)
                  Operations: 1 -> 1
                28 differences: 6 added, 2 removed, 20 changed

                """)
    }

    @Test("writes the differences as JSON")
    @MainActor
    func json() async throws {
        let result = try await compare([try fixture("shop-v1.ecore"), try fixture("shop-v2.ecore"), "--format", "json"])

        #expect(result.succeeded)
        let json = try #require(try JSONSerialization.jsonObject(with: Data(result.stdout.utf8)) as? [String: Any])
        #expect(json["kind"] as? String == "metamodel")
        let files = try #require(json["files"] as? [String: String])
        #expect(files == ["original": "shop-v1.ecore", "revised": "shop-v2.ecore"])
        let differences = try #require(json["differences"] as? [[String: Any]])
        #expect(differences.count == 28)
        let literal = try #require(differences.first { $0["path"] as? String == "Status.SHIPPED" })
        #expect(literal["change"] as? String == "changed")
        #expect(literal["element"] as? String == "literal")
        #expect(literal["property"] as? String == "value")
        #expect(literal["original"] as? String == "2")
        #expect(literal["revised"] as? String == "3")
        let money = try #require(differences.first { $0["path"] as? String == "Money" })
        #expect(money["element"] as? String == "dataType")
        let summary = try #require(json["summary"] as? [String: Int])
        #expect(summary == ["differences": 28, "added": 6, "removed": 2, "changed": 20])
        #expect(json["elementCounts"] == nil)
    }

    @Test("writes the summary counts as JSON")
    @MainActor
    func jsonSummary() async throws {
        let result = try await compare([
            try fixture("shop-v1.ecore"), try fixture("shop-v2.ecore"), "--format", "json", "--summary",
        ])

        #expect(result.succeeded)
        let json = try #require(try JSONSerialization.jsonObject(with: Data(result.stdout.utf8)) as? [String: Any])
        #expect(json["differences"] == nil)
        let counts = try #require(json["elementCounts"] as? [[String: Any]])
        #expect(counts.map { $0["name"] as? String } == [
            "Packages", "Classes", "Enumerations", "Data types", "Attributes", "References", "Operations",
        ])
        #expect(counts[1]["original"] as? Int == 6)
        #expect(counts[1]["revised"] as? Int == 8)
        #expect(counts[1]["difference"] as? Int == 2)
    }

    @Test("pairs single root packages of different names")
    @MainActor
    func renamedRoot() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let original = directory.appendingPathComponent("legacy.ecore")
        let revised = directory.appendingPathComponent("improved.ecore")
        try Self.package(name: "legacy", uri: "http://example.org/legacy", classes: ["Order", "Item"])
            .write(to: original, atomically: true, encoding: .utf8)
        try Self.package(name: "improved", uri: "http://example.org/improved", classes: ["Order", "Customer"])
            .write(to: revised, atomically: true, encoding: .utf8)

        let result = try await compare([original.path, revised.path])

        #expect(
            result.stdout == """
                Comparing metamodels: legacy.ecore -> improved.ecore
                ~ package legacy name: legacy -> improved
                ~ package legacy nsURI: http://example.org/legacy -> http://example.org/improved
                ~ package legacy nsPrefix: legacy -> improved
                - class Item
                + class Customer
                5 differences: 1 added, 1 removed, 3 changed

                """)
    }

    @Test("matches root packages by name when a metamodel has several")
    @MainActor
    func severalRoots() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let original = directory.appendingPathComponent("original.ecore")
        let revised = directory.appendingPathComponent("revised.ecore")
        let first = Self.package(name: "alpha", uri: "http://example.org/alpha", classes: ["A"], root: false)
        let second = Self.package(name: "beta", uri: "http://example.org/beta", classes: ["B"], root: false)
        let third = Self.package(name: "gamma", uri: "http://example.org/gamma", classes: ["C"], root: false)
        try Self.wrapped([first, second]).write(to: original, atomically: true, encoding: .utf8)
        try Self.wrapped([first, third]).write(to: revised, atomically: true, encoding: .utf8)

        let result = try await compare([original.path, revised.path])

        #expect(
            result.stdout == """
                Comparing metamodels: original.ecore -> revised.ecore
                - package beta: http://example.org/beta
                + package gamma: http://example.org/gamma
                2 differences: 1 added, 1 removed, 0 changed

                """)
    }

    @Test("reports removed literals, classes, references and packages when the comparison is reversed")
    @MainActor
    func reversed() async throws {
        let result = try await compare([try fixture("shop-v2.ecore"), try fixture("shop-v1.ecore")])

        #expect(result.stdout.contains("\n- literal Status.CANCELLED: 4\n"))
        #expect(result.stdout.contains("\n- class Entity: abstract\n"))
        #expect(result.stdout.contains("\n- reference Shop.products: Product [0..*], containment\n"))
        #expect(result.stdout.contains("\n~ feature Item.product kind: reference -> attribute\n"))
        #expect(result.stdout.contains("\n+ class Coupon\n"))
        #expect(result.stdout.hasSuffix("- package billing: http://example.org/shop/2.0/billing\n28 differences: 2 added, 6 removed, 20 changed\n"))
    }

    @Test("describes added and removed enumerations, data types, operations and opposites")
    @MainActor
    func descriptions() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let original = directory.appendingPathComponent("before.ecore")
        let revised = directory.appendingPathComponent("after.ecore")
        let string = "ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"
        try Self.document(
            """
              <eClassifiers xsi:type="ecore:EClass" name="Node">
                <eOperations name="describe" eType="\(string)"/>
                <eStructuralFeatures xsi:type="ecore:EReference" name="next" eType="#//Node" eOpposite="#//Node/previous"/>
                <eStructuralFeatures xsi:type="ecore:EReference" name="previous" eType="#//Node" eOpposite="#//Node/next"/>
              </eClassifiers>
              <eClassifiers xsi:type="ecore:EDataType" name="Path" instanceClassName="java.nio.file.Path"/>
            """
        ).write(to: original, atomically: true, encoding: .utf8)
        try Self.document(
            """
              <eClassifiers xsi:type="ecore:EClass" name="Node" abstract="true">
                <eOperations name="rename" lowerBound="1" upperBound="-1" eType="\(string)">
                  <eParameters name="names" upperBound="-1" eType="\(string)"/>
                </eOperations>
              </eClassifiers>
              <eClassifiers xsi:type="ecore:EEnum" name="Colour">
                <eLiterals name="RED"/>
                <eLiterals name="GREEN" value="1"/>
              </eClassifiers>
              <eClassifiers xsi:type="ecore:EDataType" name="Size"/>
            """
        ).write(to: revised, atomically: true, encoding: .utf8)

        let result = try await compare([original.path, revised.path])

        #expect(
            result.stdout == """
                Comparing metamodels: before.ecore -> after.ecore
                ~ class Node abstract: false -> true
                - reference Node.next: Node [0..1], opposite Node.previous
                - reference Node.previous: Node [0..1], opposite Node.next
                - operation Node.describe: describe(): EString
                + operation Node.rename: rename(names: EString [0..*]): EString [1..*]
                - data type Path: java.nio.file.Path
                + enumeration Colour: RED, GREEN
                + data type Size
                8 differences: 3 added, 4 removed, 1 changed

                """)
    }

    /// An Ecore document with one package named `graph` that holds the given classifiers.
    ///
    /// - Parameter classifiers: The XML of the classifiers.
    /// - Returns: The XML text.
    static func document(_ classifiers: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="graph" nsURI="http://example.org/graph" nsPrefix="graph">
        \(classifiers)
        </ecore:EPackage>

        """
    }

    /// An Ecore package with empty classes.
    ///
    /// - Parameters:
    ///   - name: The name and prefix of the package.
    ///   - uri: The namespace URI.
    ///   - classes: The names of the classes.
    ///   - root: Whether the package is the root element of a document.
    /// - Returns: The XML text.
    static func package(name: String, uri: String, classes: [String], root: Bool = true) -> String {
        let namespaces = root
            ? " xmi:version=\"2.0\" xmlns:xmi=\"http://www.omg.org/XMI\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:ecore=\"http://www.eclipse.org/emf/2002/Ecore\""
            : ""
        let body = classes.map { "  <eClassifiers xsi:type=\"ecore:EClass\" name=\"\($0)\"/>\n" }.joined()
        let package = "<ecore:EPackage\(namespaces) name=\"\(name)\" nsURI=\"\(uri)\" nsPrefix=\"\(name)\">\n\(body)</ecore:EPackage>\n"
        return root ? "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + package : package
    }

    /// Several Ecore packages in one XMI document.
    ///
    /// - Parameter packages: The packages.
    /// - Returns: The XML text.
    static func wrapped(_ packages: [String]) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore">
        \(packages.joined())</xmi:XMI>

        """
    }
}

@Suite("swift-ecore compare - Models")
struct CompareModelTests {
    @Test("reports added, removed and changed objects")
    @MainActor
    func differences() async throws {
        let result = try await compare([
            try fixture("shop-v1.xmi"), try fixture("shop-v1-revised.xmi"), "-m", try fixture("shop-v1.ecore"),
        ])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(
            result.stdout == """
                Comparing models: shop-v1.xmi -> shop-v1-revised.xmi
                ~ object Customer 'Grace' (//@customers.1) email: "grace@example.org" -> "grace@example.com"
                ~ object Customer 'Grace' (//@customers.1) orders: [] -> [Order 'A-3']
                ~ object Order 'A-1' (//@orders.0) status: "PAID" -> "SHIPPED"
                ~ object Item 'Milk' (//@orders.0/@items.1) quantity: 1 -> 3
                - object Order 'A-2' (//@orders.1)
                + object Order 'A-3' (//@orders.1)
                6 differences: 1 added, 1 removed, 4 changed

                """)
    }

    @Test("reports changed attribute values and references by label")
    @MainActor
    func references() async throws {
        let staff = try loadTestResource(named: "staff.xmi", subdirectory: "xmi").path
        let metamodel = try loadTestResource(named: "staff.ecore", subdirectory: "ecore").path

        let result = try await compare([staff, try fixture("staff-revised.xmi"), "--metamodel", metamodel])

        #expect(
            result.stdout == """
                Comparing models: staff.xmi -> staff-revised.xmi
                ~ object Employee 'Ada' (//@staff.0) grade: SENIOR -> JUNIOR
                ~ object Manager 'Grace' (//@staff.1) reports: [Employee 'Ada'] -> []
                + object Employee 'Edsger' (//@staff.2)
                3 differences: 1 added, 0 removed, 2 changed

                """)
    }

    @Test("leaves out ignored features, everywhere or of one class")
    @MainActor
    func ignore() async throws {
        let result = try await compare([
            try fixture("shop-v1.xmi"), try fixture("shop-v1-revised.xmi"), "-m", try fixture("shop-v1.ecore"),
            "--ignore", "quantity", "--ignore", "Order.status",
        ])

        #expect(!result.stdout.contains("quantity"))
        #expect(!result.stdout.contains("status"))
        #expect(result.stdout.contains("email: \"grace@example.org\" -> \"grace@example.com\"\n"))
        #expect(result.stdout.hasSuffix("4 differences: 1 added, 1 removed, 2 changed\n"))
    }

    @Test("counts the objects of each class in a summary")
    @MainActor
    func summary() async throws {
        let result = try await compare([
            try fixture("shop-v1.xmi"), try fixture("shop-v2.xmi"),
            "-m", try fixture("shop-v1.ecore"), "-m", try fixture("shop-v2.ecore"), "--summary",
        ])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(
            result.stdout == """
                Comparing models: shop-v1.xmi -> shop-v2.xmi
                Objects per class:
                  Customer: 2 -> 2
                  Item: 2 -> 2
                  Order: 2 -> 2
                  Product: 0 -> 2 (+2)
                  Shop: 1 -> 1
                  Total: 7 -> 9 (+2)
                Objects: 2 added, 0 removed, 4 changed, 3 unchanged
                6 differences: 2 added, 0 removed, 4 changed

                """)
    }

    @Test("compares a legacy and a migrated model read with both metamodels")
    @MainActor
    func migrated() async throws {
        let result = try await compare([
            try fixture("shop-v1.xmi"), try fixture("shop-v2.xmi"),
            "-m", try fixture("shop-v1.ecore"), "-m", try fixture("shop-v2.ecore"),
        ])

        #expect(
            result.stdout == """
                Comparing models: shop-v1.xmi -> shop-v2.xmi
                ~ object Customer 'Ada' (//@customers.0) orders: [Order 'A-1'] -> []
                ~ object Item 'Tea' (//@orders.0/@items.0) product: "Tea" -> Product 'Tea'
                ~ object Item 'Milk' (//@orders.0/@items.1) product: "Milk" -> Product 'Milk'
                ~ object Order 'A-2' (//@orders.1) note: "Leave at the door" -> null
                + object Product 'Tea' (//@products.0)
                + object Product 'Milk' (//@products.1)
                6 differences: 2 added, 0 removed, 4 changed

                """)
    }

    @Test("finds no differences between a model and itself without a metamodel")
    @MainActor
    func withoutMetamodel() async throws {
        let staff = try loadTestResource(named: "staff.xmi", subdirectory: "xmi").path

        let same = try await compare([staff, staff])
        let changed = try await compare([staff, try fixture("staff-revised.xmi")])

        #expect(same.stdout == "Comparing models: staff.xmi -> staff.xmi\nNo differences\n")
        #expect(changed.stdout.contains("~ object Manager 'Grace' (//@staff.1) reports: Employee 'Ada' -> null\n"))
    }

    @Test("describes references into other documents with their document")
    @MainActor
    func externalReferences() async throws {
        let resolved = try loadTestResource(named: "enterprise-project.xmi", subdirectory: "xmi").path
        let dangling = try loadTestResource(named: "enterprise-dangling.xmi", subdirectory: "xmi").path
        let metamodel = try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore").path

        let result = try await compare([resolved, dangling, "-m", metamodel])

        #expect(
            result.stdout.contains(
                "~ object Department 'Projects' (/) partners: [Department 'Finance' in enterprise-shared.xmi#/1] -> [enterprise-shared.xmi#/5 (unresolved)]\n"
            ))
    }

    @Test("finds no differences between the same model in two formats")
    @MainActor
    func crossFormat() async throws {
        let xmi = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi").path
        let json = try loadTestResource(named: "enterprise.json", subdirectory: "json").path
        let metamodel = try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore").path

        let result = try await compare([xmi, json, "-m", metamodel, "--exit-code"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout == "Comparing models: enterprise.xmi -> enterprise.json\nNo differences\n")
    }

    @Test("warns that models in two formats read without a metamodel name their classes differently")
    @MainActor
    func crossFormatWithoutMetamodel() async throws {
        let xmi = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi").path
        let json = try loadTestResource(named: "enterprise.json", subdirectory: "json").path

        let result = try await compare([xmi, json])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(
            result.stderr
                == "warning: enterprise.xmi (XMI) and enterprise.json (JSON) were read without a metamodel, "
                + "so each format names the classes of their objects in its own way and the same objects may be "
                + "reported as removed and added; give the metamodel of the models with --metamodel "
                + "<file.ecore> to compare them by their classes\n")
        #expect(!result.stdout.contains("warning"))
    }

    @Test("does not warn about models in one format or read with a metamodel")
    @MainActor
    func noCrossFormatWarning() async throws {
        let xmi = try loadTestResource(named: "enterprise.xmi", subdirectory: "xmi").path
        let json = try loadTestResource(named: "enterprise.json", subdirectory: "json").path
        let metamodel = try loadTestResource(named: "enterprise.ecore", subdirectory: "ecore").path

        let sameFormat = try await compare([xmi, xmi])
        let typed = try await compare([xmi, json, "-m", metamodel])

        #expect(sameFormat.stderr.isEmpty, "\(sameFormat.stderr)")
        #expect(typed.stderr.isEmpty, "\(typed.stderr)")
    }

    @Test("writes the differences and class counts as JSON")
    @MainActor
    func json() async throws {
        let result = try await compare([
            try fixture("shop-v1.xmi"), try fixture("shop-v2.xmi"),
            "-m", try fixture("shop-v1.ecore"), "-m", try fixture("shop-v2.ecore"), "--summary", "--format", "json",
        ])

        let json = try #require(try JSONSerialization.jsonObject(with: Data(result.stdout.utf8)) as? [String: Any])
        #expect(json["kind"] as? String == "model")
        let counts = try #require(json["classCounts"] as? [[String: Any]])
        let product = try #require(counts.first { $0["name"] as? String == "Product" })
        #expect(product["original"] as? Int == 0)
        #expect(product["revised"] as? Int == 2)
        #expect(product["difference"] as? Int == 2)
        let totals = try #require(json["totals"] as? [String: Any])
        #expect(totals["original"] as? Int == 7)
        #expect(totals["revised"] as? Int == 9)
        let summary = try #require(json["summary"] as? [String: Any])
        let objects = try #require(summary["objects"] as? [String: Int])
        #expect(objects == ["added": 2, "removed": 0, "changed": 4, "unchanged": 3])
    }

    @Test("lists every difference with its location in JSON")
    @MainActor
    func jsonDifferences() async throws {
        let result = try await compare([
            try fixture("shop-v1.xmi"), try fixture("shop-v1-revised.xmi"), "-m", try fixture("shop-v1.ecore"),
            "--format", "json",
        ])

        let json = try #require(try JSONSerialization.jsonObject(with: Data(result.stdout.utf8)) as? [String: Any])
        let differences = try #require(json["differences"] as? [[String: String]])
        #expect(differences.first == [
            "change": "changed", "element": "object", "path": "Customer 'Grace'", "location": "//@customers.1",
            "property": "email", "original": "\"grace@example.org\"", "revised": "\"grace@example.com\"",
        ])
        #expect(differences.last == [
            "change": "added", "element": "object", "path": "Order 'A-3'", "location": "//@orders.1",
        ])
    }
}

@Suite("swift-ecore compare - Options and errors")
struct CompareOptionTests {
    @Test("exits with status 1 for differences with --exit-code")
    @MainActor
    func exitCode() async throws {
        let original = try fixture("shop-v1.ecore")
        let revised = try fixture("shop-v2.ecore")

        let failing = try await compare([original, revised, "--exit-code"])
        let passing = try await compare([original, revised])

        #expect(failing.exitCode == 1)
        #expect(failing.stdout.hasSuffix("28 differences: 6 added, 2 removed, 20 changed\n"))
        #expect(failing.stderr.isEmpty)
        #expect(passing.exitCode == 0)
    }

    @Test("writes the report to a file and prints the summary line")
    @MainActor
    func output() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let file = directory.appendingPathComponent("differences.txt")

        let result = try await compare([
            try fixture("shop-v1.xmi"), try fixture("shop-v1-revised.xmi"), "-m", try fixture("shop-v1.ecore"),
            "--output", file.path,
        ])

        #expect(result.succeeded)
        #expect(result.stdout == "6 differences: 1 added, 1 removed, 4 changed\nComparison written: \(file.path)\n")
        let written = try String(contentsOf: file, encoding: .utf8)
        #expect(written.hasPrefix("Comparing models: shop-v1.xmi -> shop-v1-revised.xmi\n~ object Customer 'Grace'"))
    }

    @Test("writes a JSON report to a file")
    @MainActor
    func jsonOutput() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let file = directory.appendingPathComponent("differences.json")

        let result = try await compare([
            try fixture("shop-v1.ecore"), try fixture("shop-v2.ecore"), "-o", file.path, "--format", "json",
        ])

        #expect(result.stdout.hasSuffix("Comparison written: \(file.path)\n"))
        let json = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        #expect(json["kind"] as? String == "metamodel")
    }

    @Test("describes the inputs and metamodels in verbose mode")
    @MainActor
    func verbose() async throws {
        let result = try await compare([
            try fixture("shop-v1.xmi"), try fixture("shop-v1-revised.xmi"), "-m", try fixture("shop-v1.ecore"), "-v",
        ])

        #expect(result.succeeded)
        #expect(result.stdout.contains("Original: "))
        #expect(result.stdout.contains("Revised: "))
        #expect(result.stdout.contains("Matched 6 object(s)\n"))
    }

    @Test("refuses to compare a metamodel with a model")
    @MainActor
    func mixedKinds() async throws {
        let result = try await compare([try fixture("shop-v1.ecore"), try fixture("shop-v1.xmi")])

        #expect(result.exitCode != 0)
        #expect(result.stderr.contains("Error: Cannot compare a metamodel with a model: shop-v1.ecore is a metamodel, shop-v1.xmi is a model"))
    }

    @Test("reports a missing file")
    @MainActor
    func missingFile() async throws {
        let missing = "/tmp/nonexistent-\(UUID().uuidString).xmi"

        let result = try await compare([try fixture("shop-v1.xmi"), missing])

        #expect(result.exitCode != 0)
        #expect(result.stderr.contains("Error: File not found: \(missing)"))
    }

    @Test("reports an unsupported format")
    @MainActor
    func unsupportedFormat() async throws {
        let directory = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(directory) }
        let file = directory.appendingPathComponent("notes.txt")
        try "text".write(to: file, atomically: true, encoding: .utf8)

        let result = try await compare([file.path, file.path])

        #expect(result.exitCode != 0)
        #expect(result.stderr.contains("Error: Unsupported format: txt"))
    }
}
