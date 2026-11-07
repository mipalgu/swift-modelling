//
// MetamodelRegistrationTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import ModellingCommandLine
import Testing

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// Tests for the progress that metamodel registration reports.
///
/// Verbose output reports which metamodel is loaded and registered, while the trace of the
/// XMI parser appears only when debugging output is requested.
@Suite("Metamodel registration output", .serialized, .enabled(if: StandardOutputCapture.isSupported))
struct MetamodelRegistrationTests {
    /// The namespace URI of the test metamodel.
    static let namespace = "http://example.org/company"

    /// The marker that starts every line of the XMI parser's trace.
    static let parserTraceMarker = "[XMI"

    /// A small metamodel.
    static let metamodel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="company"
            nsURI="http://example.org/company" nsPrefix="company">
          <eClassifiers xsi:type="ecore:EClass" name="Company">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
        </ecore:EPackage>

        """

    /// Writes the metamodel to a new temporary file.
    ///
    /// - Returns: The path of the file.
    /// - Throws: Any error writing the file.
    static func writeMetamodel() throws -> String {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("Company.ecore")
        try metamodel.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    @Test("verbose registration reports progress without the parser trace")
    @MainActor
    func verboseWithoutTrace() async throws {
        let path = try Self.writeMetamodel()
        let resourceSet = ResourceSet()
        let output = try await StandardOutputCapture.capture {
            try await MetamodelRegistration.registerMetamodel(at: path, into: resourceSet, verbose: true)
        }
        #expect(output.contains("\(MetamodelRegistration.defaultAnnouncement): \(path)"), "\(output)")
        #expect(output.contains("company"), "\(output)")
        #expect(output.contains(Self.namespace), "\(output)")
        #expect(!output.contains(Self.parserTraceMarker), "\(output)")
        #expect(await resourceSet.getMetamodel(uri: Self.namespace) != nil)
    }

    @Test("quiet registration prints nothing")
    @MainActor
    func quiet() async throws {
        let path = try Self.writeMetamodel()
        let output = try await StandardOutputCapture.capture {
            try await MetamodelRegistration.registerMetamodel(at: path, into: ResourceSet())
        }
        #expect(!output.contains(MetamodelRegistration.defaultAnnouncement), "\(output)")
        #expect(!output.contains(Self.namespace), "\(output)")
        #expect(!output.contains(Self.parserTraceMarker), "\(output)")
    }

    @Test("debugging output includes the parser trace", arguments: [false, true])
    @MainActor
    func debugIncludesTrace(verbose: Bool) async throws {
        let path = try Self.writeMetamodel()
        let output = try await StandardOutputCapture.capture {
            try await MetamodelRegistration.registerMetamodel(
                at: path, into: ResourceSet(), verbose: verbose, debug: true)
        }
        #expect(output.contains(Self.parserTraceMarker), "\(output)")
        #expect(output.contains("\(MetamodelRegistration.defaultAnnouncement): \(path)") == verbose, "\(output)")
    }

    @Test("the metamodel option separates progress from the parser trace")
    @MainActor
    func metamodelOption() async throws {
        let path = try Self.writeMetamodel()
        let options = try MetamodelOptions.parse(["--metamodel", path])
        let verbose = try await StandardOutputCapture.capture {
            _ = try await options.resourceSet(verbose: true)
        }
        #expect(verbose.contains(Self.namespace), "\(verbose)")
        #expect(!verbose.contains(Self.parserTraceMarker), "\(verbose)")
        let debug = try await StandardOutputCapture.capture {
            let set = try await options.resourceSet(verbose: true, debug: true)
            #expect(await set?.getMetamodel(uri: Self.namespace) != nil)
        }
        #expect(debug.contains(Self.parserTraceMarker), "\(debug)")
    }

    // MARK: - Several root packages

    /// The namespace URI of the second root package of ``twoRoots``.
    static let peopleNamespace = "http://example.org/people"

    /// A metamodel with two root packages, the first of which refers to the second.
    static let twoRoots = """
        <?xml version="1.0" encoding="UTF-8"?>
        <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore">
          <ecore:EPackage name="company" nsURI="http://example.org/company" nsPrefix="company">
            <eClassifiers xsi:type="ecore:EClass" name="Company">
              <eStructuralFeatures xsi:type="ecore:EReference" name="staff" upperBound="-1"
                  eType="#/1/Person" containment="true"/>
            </eClassifiers>
          </ecore:EPackage>
          <ecore:EPackage name="people" nsURI="http://example.org/people" nsPrefix="people">
            <eClassifiers xsi:type="ecore:EClass" name="Person">
              <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                  eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
            </eClassifiers>
          </ecore:EPackage>
        </xmi:XMI>

        """

    /// A metamodel whose first root package, of data types, has no namespace, as in KM3.
    static let withoutNamespace = """
        <?xml version="1.0" encoding="UTF-8"?>
        <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore">
          <ecore:EPackage name="Primitives">
            <eClassifiers xsi:type="ecore:EDataType" name="Text"/>
          </ecore:EPackage>
          <ecore:EPackage name="people" nsURI="http://example.org/people" nsPrefix="people">
            <eClassifiers xsi:type="ecore:EClass" name="Person">
              <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="#/0/Text"/>
            </eClassifiers>
          </ecore:EPackage>
        </xmi:XMI>

        """

    /// Writes a metamodel to a new temporary file.
    ///
    /// - Parameter text: The metamodel.
    /// - Returns: The path of the file.
    /// - Throws: Any error writing the file.
    static func write(_ text: String) throws -> String {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("Metamodel.ecore")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    @Test("registers every root package of a file")
    @MainActor
    func everyRootPackage() async throws {
        let path = try Self.write(Self.twoRoots)
        let resourceSet = ResourceSet()
        var packages: [EPackage] = []
        let output = try await StandardOutputCapture.capture {
            packages = try await MetamodelRegistration.registerMetamodels(at: path, into: resourceSet, verbose: true)
        }
        #expect(packages.map(\.name) == ["company", "people"])
        #expect(await resourceSet.getMetamodel(uri: Self.namespace)?.name == "company")
        #expect(await resourceSet.getMetamodel(uri: Self.peopleNamespace)?.name == "people")
        #expect(output.contains(Self.namespace), "\(output)")
        #expect(output.contains(Self.peopleNamespace), "\(output)")
        let staff = (packages.first?.getClassifier("Company") as? EClass)?.eReferences.first
        #expect(staff?.eType.name == "Person")
    }

    @Test("returns the first root package when registering a file")
    @MainActor
    func firstRootPackage() async throws {
        let path = try Self.write(Self.twoRoots)
        let resourceSet = ResourceSet()
        let package = try await MetamodelRegistration.registerMetamodel(at: path, into: resourceSet)
        #expect(package.name == "company")
        #expect(await resourceSet.getMetamodel(uri: Self.peopleNamespace) != nil)
    }

    @Test("the metamodel option registers every root package")
    @MainActor
    func optionRegistersEveryRoot() async throws {
        let path = try Self.write(Self.twoRoots)
        let options = try MetamodelOptions.parse(["--metamodel", path])
        let resourceSet = try #require(try await options.resourceSet())
        #expect(Set(await resourceSet.getMetamodelURIs()) == [Self.namespace, Self.peopleNamespace])
    }

    @Test("loads a root package without a namespace, warning about it on standard error")
    @MainActor
    func withoutNamespaceWarns() async throws {
        let path = try Self.write(Self.withoutNamespace)
        let resourceSet = ResourceSet()
        var packages: [EPackage] = []
        var output = ""
        let errors = try await StandardOutputCapture.captureError {
            output = try await StandardOutputCapture.capture {
                packages = try await MetamodelRegistration.registerMetamodels(
                    at: path, into: resourceSet, verbose: true)
            }
        }
        #expect(packages.map(\.name) == ["Primitives", "people"])
        #expect(await resourceSet.getMetamodelURIs() == [Self.peopleNamespace])
        let person = packages.last?.getClassifier("Person") as? EClass
        #expect(person?.eAttributes.first?.eType.name == "Text")
        #expect(errors.contains("warning: \(path): "), "\(errors)")
        #expect(errors.contains("'Primitives'"), "\(errors)")
        #expect(errors.contains("'nsURI'"), "\(errors)")
        #expect(errors.contains("'nsPrefix'"), "\(errors)")
        #expect(!output.contains("'Primitives' with URI"), "\(output)")
        #expect(output.contains(Self.peopleNamespace), "\(output)")
    }

    @Test("writes nothing to standard error for a metamodel with namespaces")
    @MainActor
    func noWarnings() async throws {
        let path = try Self.write(Self.twoRoots)
        var errors = ""
        try await MetamodelRegistration.registerMetamodels(at: path, into: ResourceSet()) { errors += $0 }
        #expect(errors.isEmpty, "\(errors)")
    }

    @Test("writes the warnings of a metamodel through the writer it is given")
    @MainActor
    func warningsThroughWriter() async throws {
        let path = try Self.write(Self.withoutNamespace)
        var errors = ""
        let output = try await StandardOutputCapture.captureError {
            try await MetamodelRegistration.registerMetamodels(at: path, into: ResourceSet()) { errors += $0 }
        }
        #expect(errors.hasPrefix("warning: \(path): "), "\(errors)")
        #expect(errors.contains("'Primitives'"), "\(errors)")
        #expect(errors.hasSuffix("\n"), "\(errors)")
        #expect(!output.contains("warning: \(path): "), "\(output)")
    }
}

/// Captures what the process writes to standard output.
enum StandardOutputCapture {
    /// Whether standard output can be redirected on this platform.
    static var isSupported: Bool {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl)
        true
        #else
        false
        #endif
    }

    /// Runs an operation while standard output is redirected to a file and returns what it wrote.
    ///
    /// - Parameter operation: The operation whose output is captured.
    /// - Returns: The captured text.
    /// - Throws: The error of the operation, or an error creating the capture file.
    @MainActor
    static func capture(_ operation: @MainActor () async throws -> Void) async throws -> String {
        try await capture(descriptor: STDOUT_FILENO, operation)
    }

    /// Runs an operation while standard error is redirected to a file and returns what it wrote.
    ///
    /// - Parameter operation: The operation whose error output is captured.
    /// - Returns: The captured text.
    /// - Throws: The error of the operation, or an error creating the capture file.
    @MainActor
    static func captureError(_ operation: @MainActor () async throws -> Void) async throws -> String {
        try await capture(descriptor: STDERR_FILENO, operation)
    }

    /// Runs an operation while a file descriptor is redirected to a file and returns what it wrote.
    ///
    /// - Parameters:
    ///   - descriptor: The descriptor to redirect, such as that of standard output.
    ///   - operation: The operation whose output is captured.
    /// - Returns: The captured text.
    /// - Throws: The error of the operation, or an error creating the capture file.
    @MainActor
    static func capture(descriptor: Int32, _ operation: @MainActor () async throws -> Void) async throws -> String {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        defer { try? FileManager.default.removeItem(at: url) }
        let file = try FileHandle(forWritingTo: url)
        fflush(nil)
        let saved = dup(descriptor)
        dup2(file.fileDescriptor, descriptor)
        var failure: (any Error)?
        do {
            try await operation()
        } catch {
            failure = error
        }
        fflush(nil)
        dup2(saved, descriptor)
        close(saved)
        try file.close()
        if let failure { throw failure }
        return try String(contentsOf: url, encoding: .utf8)
        #else
        try await operation()
        return ""
        #endif
    }
}
