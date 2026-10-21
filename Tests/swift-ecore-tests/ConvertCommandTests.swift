import ECore
import Foundation
import Testing

// MARK: - XMI to JSON Conversion Tests

@Suite("swift-ecore convert - XMI to JSON conversion")
struct ConvertXMIToJSONTests {

    @Test("should convert valid XMI to JSON")
    @MainActor
    func testConvertXMIToJSON() async throws {
        // Given: A valid XMI file and output path
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Converting XMI to JSON (format inferred from extension)
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, outputFile.path]
        )

        // Then: Should succeed and create output file
        #expect(result.succeeded)

        // Verify output file was created
        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(!content.isEmpty)
            #expect(content.contains("{"))
        }
    }

    @Test("should display verbose conversion progress")
    @MainActor
    func testConvertXMIToJSONVerbose() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Converting with verbose flag
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, outputFile.path, "--verbose"]
        )

        // Then: Should show conversion progress
        #expect(result.succeeded)
        #expect(
            result.stdout.contains("Converting") ||
            result.stdout.contains("Inferring") ||
            result.stdout.count > 50
        )
    }

    @Test("should handle --force flag to overwrite existing files")
    @MainActor
    func testConvertWithForceFlag() async throws {
        // Given: An existing output file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // Create existing file
        try "existing content".write(to: outputFile, atomically: true, encoding: .utf8)

        // When: Converting with --force flag
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, outputFile.path, "--force"]
        )

        // Then: Should succeed and overwrite file
        #expect(result.succeeded)

        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(content != "existing content")
        }
    }
}

// MARK: - JSON to XMI Conversion Tests

@Suite("swift-ecore convert - JSON to XMI conversion")
struct ConvertJSONToXMITests {

    @Test("should convert valid JSON to XMI")
    @MainActor
    func testConvertJSONToXMI() async throws {
        // Given: A valid JSON file and output path
        let jsonFile = try loadTestResource(named: "valid-model.json", subdirectory: "json")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.xmi")

        // When: Converting JSON to XMI (format inferred from extension)
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [jsonFile.path, outputFile.path]
        )

        // Then: Should succeed and create output file
        #expect(result.succeeded)

        // Verify output file was created with XML content
        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(!content.isEmpty)
            #expect(content.contains("<?xml") || content.contains("<"))
        }
    }
}

// MARK: - Round-Trip Conversion Tests

@Suite("swift-ecore convert - Round-trip conversion")
struct ConvertRoundTripTests {

    @Test("should maintain data fidelity in XMI → JSON → XMI conversion")
    @MainActor
    func testRoundTripXMItoJSONtoXMI() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let jsonFile = tempDir.appendingPathComponent("intermediate.json")
        let finalXMIFile = tempDir.appendingPathComponent("final.xmi")

        // When: Converting XMI → JSON (format inferred from extensions)
        let xmiToJSON = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, jsonFile.path]
        )

        #expect(xmiToJSON.succeeded)

        // Then: Converting JSON → XMI (format inferred from extensions)
        let jsonToXMI = try await executeSwiftEcore(
            command: "convert",
            arguments: [jsonFile.path, finalXMIFile.path]
        )

        #expect(jsonToXMI.succeeded)

        // Verify both conversions succeeded and files exist
        #expect(FileManager.default.fileExists(atPath: jsonFile.path))
        #expect(FileManager.default.fileExists(atPath: finalXMIFile.path))

        // And: The final model holds the objects and attribute values of the original
        let original = try await XMIParser().parse(xmiFile)
        let final = try await XMIParser().parse(finalXMIFile)
        let originalSummary = await objectSummaries(of: original)
        #expect(originalSummary.count == 3)
        let finalSummary = await objectSummaries(of: final)
        #expect(finalSummary == originalSummary)
    }

    @Test("reproduces the classifiers of both roots in XMI → JSON → XMI with --metamodel")
    @MainActor
    func roundTripWithMetamodel() async throws {
        let metamodel = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")
        let xmiFile = try loadTestResource(named: "classifiers-two-roots.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }
        let jsonFile = tempDir.appendingPathComponent("intermediate.json")
        let finalXMIFile = tempDir.appendingPathComponent("final.xmi")

        let xmiToJSON = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, jsonFile.path, ConvertMetamodelTests.option, metamodel.path])
        #expect(xmiToJSON.succeeded, "\(xmiToJSON.stdout)\(xmiToJSON.stderr)")
        let jsonToXMI = try await executeSwiftEcore(
            command: "convert",
            arguments: [jsonFile.path, finalXMIFile.path, ConvertMetamodelTests.option, metamodel.path])
        #expect(jsonToXMI.succeeded, "\(jsonToXMI.stdout)\(jsonToXMI.stderr)")

        let original = try await ConvertMetamodelTests.parse(xmiFile, metamodel: metamodel)
        let final = try await ConvertMetamodelTests.parse(finalXMIFile, metamodel: metamodel)
        let originalOutline = await containmentOutline(of: original)
        #expect(originalOutline == [
            "Package name=library",
            "  DataType name=String",
            "  Class isAbstract=true name=Book",
            "    Attribute name=title type->String",
            "Package name=shop",
            "  Class name=Order",
            "  DataType name=Money",
        ])
        let finalOutline = await containmentOutline(of: final)
        #expect(finalOutline == originalOutline)
    }
}

// MARK: - Metamodel-Aware Conversion Tests

@Suite("swift-ecore convert - Metamodels")
struct ConvertMetamodelTests {
    /// The long name of the option that registers a metamodel.
    static let option = "--metamodel"

    /// The namespace URI of the classifier metamodel.
    static let namespace = "http://example.org/classifiers"

    /// Parses an instance of the classifier metamodel in process.
    ///
    /// - Parameters:
    ///   - url: The XMI document to parse.
    ///   - metamodel: The Ecore file of the classifier metamodel.
    /// - Returns: The parsed resource, which belongs to a resource set with the metamodel.
    @MainActor
    static func parse(_ url: URL, metamodel: URL) async throws -> Resource {
        let resourceSet = ResourceSet()
        let package = try await EPackage(url: metamodel)
        await resourceSet.registerMetamodel(package, uri: package.nsURI)
        return try await XMIParser(resourceSet: resourceSet).parse(url)
    }

    /// Converts the two-root classifier model to JSON with the metamodel.
    ///
    /// - Parameter directory: The directory that receives the JSON document.
    /// - Returns: The result of the command and the decoded JSON roots.
    @MainActor
    private func convertToJSON(in directory: URL) async throws -> (SubprocessResult, [[String: Any]]) {
        let metamodel = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")
        let xmiFile = try loadTestResource(named: "classifiers-two-roots.xmi", subdirectory: "xmi")
        let jsonFile = directory.appendingPathComponent("classifiers.json")
        let result = try await executeSwiftEcore(
            command: "convert", arguments: [xmiFile.path, jsonFile.path, Self.option, metamodel.path])
        let data = try Data(contentsOf: jsonFile)
        let roots = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return (result, roots)
    }

    @Test("writes package-qualified classes with --metamodel")
    @MainActor
    func qualifiedClasses() async throws {
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let (result, roots) = try await convertToJSON(in: tempDir)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(roots.map { $0["eClass"] as? String } == Array(repeating: Self.namespace + "#//Package", count: 2))
        let classifiers = roots.first?["classifiers"] as? [[String: Any]] ?? []
        #expect(classifiers.map { $0["eClass"] as? String } == [Self.namespace + "#//DataType", Self.namespace + "#//Class"])
    }

    @Test("writes non-containment references as $ref entries with --metamodel")
    @MainActor
    func referenceEntries() async throws {
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let (result, roots) = try await convertToJSON(in: tempDir)

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let classifiers = roots.first?["classifiers"] as? [[String: Any]] ?? []
        let attributes = classifiers.last?["attributes"] as? [[String: Any]] ?? []
        let type = attributes.first?["type"] as? [String: Any]
        let fragment = try #require(type?["$ref"] as? String, "\(attributes)")
        #expect(fragment.hasSuffix("@classifiers.0"))
    }

    @Test("reports a metamodel file that does not exist")
    @MainActor
    func missingMetamodel() async throws {
        let xmiFile = try loadTestResource(named: "classifiers-two-roots.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }
        let missing = tempDir.appendingPathComponent("missing.ecore").path

        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, tempDir.appendingPathComponent("out.json").path, Self.option, missing])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("File not found"), "\(result.stderr)")
        #expect(result.stderr.contains(missing))
    }

    @Test("lists --metamodel in the help")
    @MainActor
    func helpListsMetamodel() async throws {
        let result = try await executeSwiftEcore(command: "convert", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
    }
}

// MARK: - Model Summaries

/// Describes every object of a resource by its class and attribute values.
///
/// Values that are object identifiers, which differ between loads, are left out. The
/// descriptions are sorted, so the summary does not depend on the order of the objects.
///
/// - Parameter resource: The resource to describe.
/// - Returns: One line for each object, such as `Element name=Element1 value=42`.
func objectSummaries(of resource: Resource) async -> [String] {
    var lines: [String] = []
    for case let object as DynamicEObject in await resource.getAllObjects() {
        let values = object.getFeatureNames().sorted().compactMap { name -> String? in
            guard let value = object.eGet(name), !(value is UUID), !(value is [UUID]) else { return nil }
            return "\(name)=\(value)"
        }
        lines.append(([object.eClass.name] + values).joined(separator: " "))
    }
    return lines.sorted()
}

/// Describes the containment tree of a resource whose classes come from a metamodel.
///
/// Each object is a line, indented by its depth, with its class name, its set attributes and
/// the names of the objects that its non-containment references without opposites refer to.
///
/// - Parameter resource: The resource to describe.
/// - Returns: The lines in depth-first containment order of the roots.
func containmentOutline(of resource: Resource) async -> [String] {
    var lines: [String] = []
    for root in await resource.getRootObjects() {
        await appendOutline(of: root, depth: 0, in: resource, to: &lines)
    }
    return lines
}

/// Appends the outline of an object and its contents.
///
/// - Parameters:
///   - object: The object to describe.
///   - depth: The containment depth of the object.
///   - resource: The resource that holds the object.
///   - lines: The outline to extend.
private func appendOutline(
    of object: any EObject, depth: Int, in resource: Resource, to lines: inout [String]
) async {
    guard let object = object as? DynamicEObject else { return }
    let eClass = object.eClass
    var parts = [String(repeating: "  ", count: depth) + eClass.name]
    for attribute in eClass.eAllAttributes.sorted(by: { $0.name < $1.name }) where object.eIsSet(attribute) {
        parts.append("\(attribute.name)=\(object.eGet(attribute).map { "\($0)" } ?? "")")
    }
    for reference in eClass.eAllReferences.sorted(by: { $0.name < $1.name })
    where !reference.containment && reference.opposite == nil && object.eIsSet(reference) {
        let targets = await resource.resolveReference(reference, from: object)
        let names = targets.compactMap { ($0 as? DynamicEObject)?.eGet("name") as? String }
        parts.append("\(reference.name)->" + names.joined(separator: ","))
    }
    lines.append(parts.joined(separator: " "))
    for child in await resource.eContents(of: object) {
        await appendOutline(of: child, depth: depth + 1, in: resource, to: &lines)
    }
}

// MARK: - Error Handling Tests

@Suite("swift-ecore convert - Error handling")
struct ConvertErrorHandlingTests {

    @Test("should report error for missing input file")
    @MainActor
    func testConvertMissingInputFile() async throws {
        // Given: A non-existent input file
        let missingPath = "/tmp/nonexistent-\(UUID().uuidString).xmi"
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Attempting to convert
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [missingPath, outputFile.path]
        )

        // Then: Should report error (exit code checked by test framework)
        #expect(!result.succeeded)
        #expect(
            result.stderr.contains("not found") ||
            result.stderr.contains("does not exist") ||
            result.stdout.contains("not found") ||
            result.stdout.contains("Failed")
        )
    }

    @Test("should report error for unsupported output format")
    @MainActor
    func testConvertUnsupportedFormat() async throws {
        // Given: A valid input file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.yaml")

        // When: Converting to unsupported format using explicit flag
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, outputFile.path, "--output-format", "yaml"]
        )

        // Then: Should report unsupported format error
        #expect(
            result.stderr.contains("unsupported") ||
            result.stderr.contains("format") ||
            result.stdout.contains("unsupported") ||
            result.stdout.contains("format")
        )
    }

    @Test("should report error for invalid input file")
    @MainActor
    func testConvertInvalidInputFile() async throws {
        // Given: An invalid XMI file
        let invalidFile = try loadTestResource(named: "invalid-syntax.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Attempting to convert
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [invalidFile.path, outputFile.path]
        )

        // Then: Should report conversion error
        #expect(!result.succeeded)
        #expect(
            result.stderr.contains("Error") ||
            result.stderr.contains("Failed") ||
            result.stderr.contains("error") ||
            result.stdout.contains("Error") ||
            result.stdout.contains("Failed") ||
            result.stdout.contains("error")
        )
    }
}

// MARK: - Explicit Format Flags Tests

@Suite("swift-ecore convert - Explicit format flags")
struct ConvertExplicitFormatTests {

    @Test("should use explicit --input-format flag")
    @MainActor
    func testExplicitInputFormat() async throws {
        // Given: An XMI file with non-standard extension
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        // Create a copy with .dat extension
        let datFile = tempDir.appendingPathComponent("input.dat")
        try FileManager.default.copyItem(at: xmiFile, to: datFile)

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Converting with explicit input format
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [datFile.path, outputFile.path, "--input-format", "xmi"]
        )

        // Then: Should succeed
        #expect(result.succeeded)
        #expect(FileManager.default.fileExists(atPath: outputFile.path))
    }

    @Test("should use explicit --output-format flag")
    @MainActor
    func testExplicitOutputFormat() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.dat")

        // When: Converting with explicit output format
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, outputFile.path, "--output-format", "json"]
        )

        // Then: Should create JSON in .dat file
        #expect(result.succeeded)

        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(content.contains("{"))
            #expect(content.contains("eClass"))
        }
    }

    @Test("should use both explicit format flags")
    @MainActor
    func testBothExplicitFormats() async throws {
        // Given: Test resources
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        // Create JSON with .dat extension
        let jsonContent = """
        {
          "eClass": "Root",
          "elements": []
        }
        """
        let inputFile = tempDir.appendingPathComponent("input.dat")
        try jsonContent.write(to: inputFile, atomically: true, encoding: .utf8)

        let outputFile = tempDir.appendingPathComponent("output.dat")

        // When: Converting with both explicit formats
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [
                inputFile.path,
                outputFile.path,
                "--input-format", "json",
                "--output-format", "xmi"
            ]
        )

        // Then: Should create XMI in .dat file
        #expect(result.succeeded)

        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile, encoding: .utf8)
            #expect(content.contains("<?xml") || content.contains("<"))
        }
    }

    @Test("should show format source in verbose output")
    @MainActor
    func testVerboseFormatSource() async throws {
        // Given: A valid XMI file
        let xmiFile = try loadTestResource(named: "valid-model.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let outputFile = tempDir.appendingPathComponent("output.json")

        // When: Converting with explicit formats and verbose
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [
                xmiFile.path,
                outputFile.path,
                "--input-format", "xmi",
                "--output-format", "json",
                "--verbose"
            ]
        )

        // Then: Should show format source in output
        #expect(result.succeeded)
        #expect(result.stdout.contains("Using explicit input format"))
        #expect(result.stdout.contains("Using explicit output format"))
    }
}

// MARK: - Help and Usage Tests

@Suite("swift-ecore convert - Help and usage")
struct ConvertHelpTests {

    @Test("should display help when --help flag is used")
    @MainActor
    func testConvertHelp() async throws {
        // Given/When: Running convert with --help
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: ["--help"]
        )

        // Then: Should display help information
        #expect(result.succeeded)
        #expect(result.stdout.contains("convert") || result.stdout.contains("USAGE"))
        #expect(
            result.stdout.contains("--format") ||
            result.stdout.contains("--force") ||
            result.stdout.contains("option")
        )
    }
}

// MARK: - Lossiness Warning Tests

@Suite("swift-ecore convert - Lossiness warnings")
struct ConvertWarningTests {
    /// The prefix of a warning line on standard error.
    static let warningPrefix = "warning: "

    /// The prefix of the line that suggests giving a metamodel.
    static let hintPrefix = "hint: "

    /// The lines of an output that start with a prefix.
    ///
    /// - Parameters:
    ///   - text: The output of a command.
    ///   - prefix: The prefix of the lines to keep.
    /// - Returns: The matching lines, in order.
    static func lines(of text: String, startingWith prefix: String) -> [String] {
        text.split(whereSeparator: \.isNewline).map(String.init).filter { $0.hasPrefix(prefix) }
    }

    /// Converts the two-root classifier model through JSON back to XMI.
    ///
    /// - Parameters:
    ///   - directory: The directory that receives the converted documents.
    ///   - extra: The arguments added to both conversions.
    /// - Returns: The results of both conversions and the text of the final XMI document.
    @MainActor
    private func roundTrip(
        in directory: URL, extra: [String] = []
    ) async throws -> (toJSON: SubprocessResult, toXMI: SubprocessResult, xmi: String) {
        let xmiFile = try loadTestResource(named: "classifiers-two-roots.xmi", subdirectory: "xmi")
        let jsonFile = directory.appendingPathComponent("intermediate.json")
        let finalXMIFile = directory.appendingPathComponent("final.xmi")
        let toJSON = try await executeSwiftEcore(
            command: "convert", arguments: [xmiFile.path, jsonFile.path] + extra)
        let toXMI = try await executeSwiftEcore(
            command: "convert", arguments: [jsonFile.path, finalXMIFile.path] + extra)
        let xmi = (try? String(contentsOf: finalXMIFile, encoding: .utf8)) ?? ""
        return (toJSON, toXMI, xmi)
    }

    @Test("warns on standard error about an untyped round trip and still writes the children")
    @MainActor
    func untypedRoundTripWarns() async throws {
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let (toJSON, toXMI, xmi) = try await roundTrip(in: tempDir)

        #expect(toJSON.succeeded, "\(toJSON.stdout)\(toJSON.stderr)")
        #expect(toXMI.succeeded, "\(toXMI.stdout)\(toXMI.stderr)")
        let untyped = ConversionWarning(.untypedClass(name: "Package")).message
        for result in [toJSON, toXMI] {
            let warnings = Self.lines(of: result.stderr, startingWith: Self.warningPrefix)
            #expect(warnings.contains(Self.warningPrefix + untyped), "\(result.stderr)")
            #expect(Set(warnings).count == warnings.count, "\(result.stderr)")
            #expect(Self.lines(of: result.stdout, startingWith: Self.warningPrefix).isEmpty, "\(result.stdout)")
            #expect(result.stdout.contains("Conversion completed"), "\(result.stdout)")
        }
        for name in ["library", "String", "Book", "title", "shop", "Order", "Money"] {
            #expect(xmi.contains("name=\"\(name)\""), "\(xmi)")
        }
    }

    @Test("writes no warning lines for a conversion with --metamodel")
    @MainActor
    func metamodelConversionHasNoWarnings() async throws {
        let metamodel = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let (toJSON, toXMI, _) = try await roundTrip(
            in: tempDir, extra: [ConvertMetamodelTests.option, metamodel.path])

        for result in [toJSON, toXMI] {
            #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
            #expect(Self.lines(of: result.stderr, startingWith: Self.warningPrefix).isEmpty, "\(result.stderr)")
            #expect(Self.lines(of: result.stderr, startingWith: Self.hintPrefix).isEmpty, "\(result.stderr)")
        }
    }

    @Test("suggests --metamodel once after the warnings of a conversion without a metamodel")
    @MainActor
    func hintWithoutMetamodel() async throws {
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let (toJSON, _, _) = try await roundTrip(in: tempDir)

        let hints = Self.lines(of: toJSON.stderr, startingWith: Self.hintPrefix)
        #expect(hints.count == 1, "\(toJSON.stderr)")
        #expect(hints.first?.contains(ConvertMetamodelTests.option) == true, "\(toJSON.stderr)")
        let lines = toJSON.stderr.split(whereSeparator: \.isNewline).map(String.init)
        #expect(lines.last == hints.first, "\(toJSON.stderr)")
    }
}

// MARK: - Reference Style Tests

@Suite("swift-ecore convert - Reference style")
struct ConvertReferenceStyleTests {
    /// The long name of the option that chooses the reference style.
    static let option = "--reference-style"

    /// The same-document reference of the title attribute in the plain style.
    static let plainReference = "type=\"cls:DataType /0/@classifiers.0\""

    /// Converts the two-root classifier model to XMI with the metamodel.
    ///
    /// - Parameters:
    ///   - directory: The directory that receives the XMI document.
    ///   - name: The file name of the XMI document.
    ///   - extra: The arguments after the metamodel.
    /// - Returns: The result of the command, the written document and its text.
    @MainActor
    private func convert(
        in directory: URL, name: String, extra: [String] = []
    ) async throws -> (result: SubprocessResult, url: URL, text: String) {
        let metamodel = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")
        let xmiFile = try loadTestResource(named: "classifiers-two-roots.xmi", subdirectory: "xmi")
        let output = directory.appendingPathComponent(name)
        let result = try await executeSwiftEcore(
            command: "convert",
            arguments: [xmiFile.path, output.path, ConvertMetamodelTests.option, metamodel.path] + extra)
        return (result, output, (try? String(contentsOf: output, encoding: .utf8)) ?? "")
    }

    @Test("writes same-document references without a leading # with --reference-style plain")
    @MainActor
    func plainReferences() async throws {
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let (result, _, text) = try await convert(in: tempDir, name: "plain.xmi", extra: [Self.option, "plain"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(text.contains(Self.plainReference), "\(text)")
        #expect(!text.contains("#/0/@classifiers.0"), "\(text)")
    }

    @Test("reads a document written with --reference-style plain again")
    @MainActor
    func plainReferencesLoad() async throws {
        let metamodel = try loadTestResource(named: "classifiers.ecore", subdirectory: "ecore")
        let xmiFile = try loadTestResource(named: "classifiers-two-roots.xmi", subdirectory: "xmi")
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }
        let (written, plainFile, _) = try await convert(in: tempDir, name: "plain.xmi", extra: [Self.option, "plain"])
        #expect(written.succeeded, "\(written.stdout)\(written.stderr)")
        let jsonFile = tempDir.appendingPathComponent("back.json")
        let backFile = tempDir.appendingPathComponent("back.xmi")

        let toJSON = try await executeSwiftEcore(
            command: "convert", arguments: [plainFile.path, jsonFile.path, ConvertMetamodelTests.option, metamodel.path])
        let toXMI = try await executeSwiftEcore(
            command: "convert",
            arguments: [jsonFile.path, backFile.path, ConvertMetamodelTests.option, metamodel.path, Self.option, "plain"])

        #expect(toJSON.succeeded, "\(toJSON.stdout)\(toJSON.stderr)")
        #expect(toXMI.succeeded, "\(toXMI.stdout)\(toXMI.stderr)")
        let original = await containmentOutline(of: try await ConvertMetamodelTests.parse(xmiFile, metamodel: metamodel))
        let plain = await containmentOutline(of: try await ConvertMetamodelTests.parse(plainFile, metamodel: metamodel))
        let back = await containmentOutline(of: try await ConvertMetamodelTests.parse(backFile, metamodel: metamodel))
        #expect(plain == original)
        #expect(back == original)
    }

    @Test("keeps the default output with --reference-style encoded")
    @MainActor
    func encodedIsDefault() async throws {
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let (byDefault, _, defaultText) = try await convert(in: tempDir, name: "default.xmi")
        let (encoded, _, encodedText) = try await convert(in: tempDir, name: "encoded.xmi", extra: [Self.option, "encoded"])

        #expect(byDefault.succeeded, "\(byDefault.stdout)\(byDefault.stderr)")
        #expect(encoded.succeeded, "\(encoded.stdout)\(encoded.stderr)")
        #expect(defaultText.contains("href=\"#/0/@classifiers.0\""), "\(defaultText)")
        #expect(!defaultText.contains(Self.plainReference), "\(defaultText)")
        #expect(encodedText == defaultText)
    }

    @Test("rejects a value that is not a reference style")
    @MainActor
    func rejectsUnknownStyle() async throws {
        let tempDir = try createTemporaryDirectory()
        defer { cleanupTemporaryDirectory(tempDir) }

        let (result, url, _) = try await convert(in: tempDir, name: "bad.xmi", extra: [Self.option, "fancy"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("fancy"), "\(result.stderr)")
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test("lists --reference-style and its values in the help")
    @MainActor
    func helpListsReferenceStyle() async throws {
        let result = try await executeSwiftEcore(command: "convert", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains(Self.option))
        #expect(result.stdout.contains("encoded"))
        #expect(result.stdout.contains("plain"))
        #expect(result.stdout.contains("Eclipse"))
    }
}
