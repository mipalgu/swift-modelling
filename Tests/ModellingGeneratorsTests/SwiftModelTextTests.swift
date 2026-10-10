import Foundation
import Testing

@testable import ModellingGenerators

/// Checks the text of the Swift code that the template set writes for fixtures.
@Suite("Swift model text")
struct SwiftModelTextTests {
    /// Generates a fixture and reads some of its files.
    ///
    /// - Parameters:
    ///   - fixture: The name of the fixture.
    ///   - paths: The paths of the files to read.
    /// - Returns: The text of the files in the same order.
    @MainActor
    func files(_ fixture: String, _ paths: [String]) async throws -> [String] {
        let golden = try #require(SwiftGoldenCase.named(fixture))
        let generated = try await generateSwift(golden)
        defer { generated.remove() }
        return try paths.map { try generated.text($0) }
    }

    /// Generates a fixture and reads all of its files.
    @MainActor
    func allFiles(_ fixture: String) async throws -> [String: String] {
        let golden = try #require(SwiftGoldenCase.named(fixture))
        let generated = try await generateSwift(golden)
        defer { generated.remove() }
        return Dictionary(uniqueKeysWithValues: try generated.generatedPaths().map { ($0, try generated.text($0)) })
    }

    // MARK: - Layout of the text

    @Test("Documentation comment and declaration stand on lines of their own", arguments: SwiftGoldenCase.all)
    @MainActor
    func declarationsHaveTheirOwnLines(_ golden: SwiftGoldenCase) async throws {
        let generated = try await generateSwift(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() {
            let lines = try generated.text(path).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() where index > 0 {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let declaresType = ["public protocol ", "public final class ", "public enum ", "public struct "].contains {
                    trimmed.hasPrefix($0)
                }
                if declaresType {
                    #expect(lines[index - 1] == "// @generated", "\(path): the declaration '\(trimmed)' follows the tag")
                    #expect(!line.contains("///"), "\(path): a comment shares the line of '\(trimmed)'")
                }
            }
        }
    }

    @Test("Every member of a generated file carries the generated tag", arguments: SwiftGoldenCase.all)
    @MainActor
    func membersAreTagged(_ golden: SwiftGoldenCase) async throws {
        let generated = try await generateSwift(golden)
        defer { generated.remove() }
        let members = ["public ", "private ", "case ", "var ", "static ", "init"]
        for path in generated.generatedPaths() {
            let lines = try generated.text(path).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() where index > 0 {
                let topLevel = !line.hasPrefix(" ") && line.hasPrefix("public ")
                let member =
                    line.hasPrefix("    ") && !line.hasPrefix("     ")
                    && members.contains { line.dropFirst(4).hasPrefix($0) }
                if topLevel || member {
                    #expect(
                        lines[index - 1].trimmingCharacters(in: .whitespaces) == "// @generated",
                        "\(path): '\(line.trimmingCharacters(in: .whitespaces))' lacks the generated tag")
                }
            }
        }
    }

    @Test("Files that name Ecore values import the module that declares them", arguments: SwiftGoldenCase.all)
    @MainActor
    func importsDeclareTheTypesInUse(_ golden: SwiftGoldenCase) async throws {
        let generated = try await generateSwift(golden)
        defer { generated.remove() }
        for path in generated.generatedPaths() {
            let text = try generated.text(path)
            if text.contains("EcoreValue") { #expect(text.contains("\nimport EMFBase\n"), "\(path) lacks EMFBase") }
            if text.contains(": EObject") || text.contains("EClass") {
                #expect(text.contains("\nimport ECore\n"), "\(path) lacks ECore")
            }
            if text.contains("Mutex<") { #expect(text.contains("\nimport Synchronization\n"), "\(path) lacks Synchronization") }
            #expect(!text.contains("\u{2014}"), "\(path) has an em-dash")
            let imports = text.components(separatedBy: "\n").filter { $0.hasPrefix("import ") }
            #expect(imports == imports.sorted() && Set(imports).count == imports.count, "\(path) imports in order, once")
        }
    }

    @Test("The file header names the file and carries the copyright text")
    @MainActor
    func header() async throws {
        let text = try await files("library", ["library/Book.swift"])[0]
        #expect(
            text.hasPrefix(
                "//\n//  Book.swift\n//\n//  Copyright 2026 Example Pty Ltd\n//\n\nimport ECore\nimport EMFBase\nimport Foundation\nimport Synchronization\n\n"
            ))
        let bare = try await files("bare", ["bare/Thing.swift"])[0]
        #expect(bare.hasPrefix("//\n//  Thing.swift\n//\n\nimport "))
    }

    // MARK: - Names

    @Test("Names that are Swift keywords are quoted, and members that the runtime claims are renamed")
    @MainActor
    func quotedNames() async throws {
        let all = try await allFiles("swiftnames")
        let vehicle = try #require(all["swiftnames/Vehicle.swift"])
        for name in ["guard", "class", "operator", "repeat", "where", "in", "protocol"] {
            #expect(vehicle.contains("    var `\(name)`: "), "the protocol requires `\(name)`")
            #expect(vehicle.contains("    public var `\(name)`: "), "the class has `\(name)`")
        }
        #expect(vehicle.contains("    var id_: String? { get set }"))
        #expect(vehicle.contains("    var hash_: Int { get set }"))
        #expect(vehicle.contains(#"case "id": return self.id_"#))
        #expect(vehicle.contains(#"case "guard": return self.`guard`"#))
        let type = try #require(all["swiftnames/Type.swift"])
        #expect(type.contains("public protocol `Type`: EObject, AnyObject {"))
        #expect(type.contains("    var `default`: String? { get set }"))
        #expect(vehicle.contains("public protocol Vehicle: `Type` {"))
        #expect(vehicle.contains("var kinds: [any `Type`] { get set }"))
        for file in ["Self", "Protocol"] {
            let text = try #require(all["swiftnames/parts/\(file).swift"])
            #expect(text.contains("public final class `\(file)`: EObject {"))
            #expect(text.contains("\n//  \(file).swift\n"), "the file is not quoted")
        }
    }

    @Test("Types that would hide a standard type are renamed, and their files are too")
    @MainActor
    func renamedTypes() async throws {
        let all = try await allFiles("swiftnames")
        let date = try #require(all["swiftnames/Date_.swift"])
        #expect(date.contains("public final class Date_: EObject {"))
        #expect(date.contains("    public var when: Date? {"))
        #expect(date.contains("//  Date_.swift"))
        let string = try #require(all["swiftnames/parts/String_.swift"])
        #expect(string.contains("public final class String_: EObject {"))
        let factory = try #require(all["swiftnames/SwiftnamesFactory.swift"])
        #expect(factory.contains("public func createDate() -> Date_ { Date_() }"))
        let package = try #require(all["swiftnames/SwiftnamesPackage.swift"])
        #expect(package.contains("public let eDate: EClass"))
    }

    @Test("Packages are named from their prefix, and nested packages get directories of their own")
    @MainActor
    func packageNames() async throws {
        let org = try await allFiles("organisation")
        #expect(Set(org.keys).isSuperset(of: ["organisation/OrgPackage.swift", "organisation/OrgFactory.swift"]))
        #expect(org["organisation/OrgPackage.swift"]?.contains("public struct OrgPackage: Sendable {") == true)
        let nested = try await allFiles("nested")
        let projects = try #require(nested["company/projects/ProjPackage.swift"])
        #expect(projects.contains("public struct ProjPackage: Sendable {"))
        let archive = try #require(nested["company/projects/archive/Record.swift"])
        #expect(archive.contains("ArchivePackage.shared.eRecord"))
        #expect(archive.contains("public var project: Project? {"))
    }

    // MARK: - Protocols and classes

    @Test("Abstract classes and interfaces are protocols; classes with instances are final classes")
    @MainActor
    func protocolsAndClasses() async throws {
        let all = try await allFiles("library")
        let named = try #require(all["library/Named.swift"])
        #expect(named.contains("public protocol Named: EObject, AnyObject {"))
        #expect(!named.contains("final class"))
        let lendable = try #require(all["library/Lendable.swift"])
        #expect(lendable.contains("public protocol Lendable: EObject, AnyObject {"))
        let book = try #require(all["library/Book.swift"])
        #expect(book.contains("public final class Book: EObject, Named, Lendable {"))
        #expect(!book.contains("protocol Book"))
        #expect(book.contains("public static func == (lhs: Book, rhs: Book) -> Bool { lhs.id == rhs.id }"))
        #expect(book.contains("public func hash(into hasher: inout Hasher) { hasher.combine(id) }"))
        #expect(book.contains("public var eClass: EClass { LibraryPackage.shared.eBook }"))
        #expect(book.contains("public typealias Classifier = EClass"))
        #expect(book.contains("private let eStorage: Mutex<EStorage>"))
    }

    @Test("A class that others extend is a protocol with a final class that carries a suffix")
    @MainActor
    func extendedClasses() async throws {
        let all = try await allFiles("swiftnames")
        let vehicle = try #require(all["swiftnames/Vehicle.swift"])
        #expect(vehicle.contains("public protocol Vehicle: `Type` {"))
        #expect(vehicle.contains("public final class VehicleImpl: EObject, Vehicle {"))
        #expect(vehicle.contains("/// The implementation of the Vehicle protocol."))
        let truck = try #require(all["swiftnames/Truck.swift"])
        #expect(truck.contains("public final class Truck: EObject, Vehicle {"))
        let driver = try #require(all["swiftnames/Driver.swift"])
        #expect(driver.contains("public var vehicle: (any Vehicle)? {"))
        let factory = try #require(all["swiftnames/SwiftnamesFactory.swift"])
        #expect(factory.contains("public func createVehicle() -> VehicleImpl { VehicleImpl() }"))
        #expect(factory.contains("public func createTruck() -> Truck { Truck() }"))
        #expect(!factory.contains("createType"))
        #expect(factory.contains(#"case "Vehicle": return createVehicle()"#))
    }

    @Test("Classes are sendable by holding their values in a lock rather than in mutable properties")
    @MainActor
    func sendableClasses() async throws {
        let all = try await allFiles("library")
        for (path, text) in all where text.contains("public final class") {
            #expect(!text.contains("@unchecked"), "\(path) is unchecked")
            #expect(text.contains("private struct EStorage: Sendable {"), "\(path) has stored values")
            #expect(text.contains("eStorage.withLock"), "\(path) reads under the lock")
        }
    }

    // MARK: - Features

    @Test("Attributes with a primitive type or an enumeration always have a value; others are optional")
    @MainActor
    func attributeTypes() async throws {
        let book = try await files("library", ["library/Book.swift"])[0]
        #expect(book.contains("        var loanDays: Int = 14\n"))
        #expect(book.contains("        var onLoan: Bool = false\n"))
        #expect(book.contains("        var name: String? = nil\n"))
        #expect(book.contains("        var category: BookCategory = .Mystery\n"))
        #expect(book.contains("        var isbn: ISBN? = nil\n"))
        let writer = try await files("library", ["library/Writer.swift"])[0]
        #expect(writer.contains("        var aliases: [String] = []\n"))
        #expect(writer.contains("        var books: [Book] = []\n"))
    }

    @Test("Defaults of the model become Swift values")
    @MainActor
    func defaults() async throws {
        let all = try await allFiles("swiftnames")
        let truck = try #require(all["swiftnames/Truck.swift"])
        #expect(truck.contains("        var load: Double = 2.5\n"))
        #expect(truck.contains(#"        var plate: String? = "N/A""# + "\n"))
        #expect(truck.contains("        var hue: Hue = .green\n"))
        #expect(truck.contains("        var shades: [Hue] = []\n"))
        let type = try #require(all["swiftnames/Type.swift"])
        #expect(type.contains(#"public protocol `Type`"#))
        let vehicle = try #require(all["swiftnames/Vehicle.swift"])
        #expect(vehicle.contains(#"        var name: String? = "say \"hi\"\n\\there""# + "\n"))
        let values = try #require(all["swiftnames/Values.swift"])
        #expect(values.contains(#"        var initial: Character = "x""# + "\n"))
        #expect(values.contains("        var huge: Int64 = 99999999999\n"))
        #expect(values.contains("        var ratio: Float = 0.5\n"))
        #expect(values.contains("        var count: Int? = 7\n"))
        #expect(values.contains("        var flag: Bool? = nil\n"))
        #expect(values.contains("        var small: Int16 = 0\n"))
        #expect(values.contains("        var tiny: Int8 = 0\n"))
        #expect(values.contains("        var big: EBigInteger? = nil\n"))
        #expect(values.contains("        var money: Decimal? = nil\n"))
        #expect(values.contains("        var bytes: [Int8]? = nil\n"))
        #expect(values.contains("        var payload: (any EcoreValue)? = nil\n"))
        #expect(values.contains("        var stamp: Stamp? = nil\n"))
        #expect(values.contains("        var mood: Mood? = nil\n"), "an enumeration without literals has no default")
    }

    @Test("Single references that do not contain are weak; contained and many-valued ones are strong")
    @MainActor
    func weakReferences() async throws {
        let book = try await files("library", ["library/Book.swift"])[0]
        #expect(book.contains("        var author = EWeakReference(nil)\n"))
        #expect(book.contains("get { eStorage.withLock { $0.author.object as? Writer } }"))
        #expect(book.contains("private struct EWeakReference: Sendable {"))
        let library = try await files("library", ["library/Library.swift"])[0]
        #expect(library.contains("        var books: [Book] = []\n"))
        #expect(!library.contains("EWeakReference"))
        let canvas = try await files("classes", ["classes/Canvas.swift"])[0]
        #expect(canvas.contains("        var background: (any Shape)? = nil\n"), "a containment is strong")
        #expect(canvas.contains("        var selected = EWeakReference(nil)\n"))
        #expect(canvas.contains("        var favourites: [any Shape] = []\n"))
        let ecore = try await files("ecoretypes", ["bridge/Span.swift"])[0]
        #expect(ecore.contains("        var supports: [any EObject] = []\n"))
        #expect(ecore.contains("        var next = EWeakReference(nil)\n"))
        #expect(ecore.contains("        var payload: (any EcoreValue)? = nil\n"))
    }

    @Test("Setting a reference keeps its opposite in step")
    @MainActor
    func opposites() async throws {
        let book = try await files("library", ["library/Book.swift"])[0]
        #expect(book.contains("previous?.books.removeAll { $0 === self }"))
        #expect(book.contains("newValue.books.append(self)"))
        let driver = try await files("swiftnames", ["swiftnames/Driver.swift"])[0]
        #expect(driver.contains("if let previous, previous.driver === self { previous.driver = nil }"))
        #expect(driver.contains("if let newValue, newValue.driver !== self { newValue.driver = self }"))
        let writer = try await files("library", ["library/Writer.swift"])[0]
        #expect(!writer.contains("removeAll"), "the many-valued end keeps a plain array")
    }

    @Test("The reflective methods switch on the name of the feature")
    @MainActor
    func reflection() async throws {
        let book = try await files("library", ["library/Book.swift"])[0]
        #expect(book.contains("public func eGet(_ feature: some EStructuralFeature) -> (any EcoreValue)? {"))
        #expect(book.contains("public func eSet(_ feature: some EStructuralFeature, _ value: (any EcoreValue)?) {"))
        #expect(book.contains("public func eIsSet(_ feature: some EStructuralFeature) -> Bool {"))
        #expect(book.contains("public func eUnset(_ feature: some EStructuralFeature) {"))
        #expect(book.contains(#"case "pages": self.pages = (value as? Int) ?? 100"#))
        #expect(book.contains(#"case "pages": return self.pages != 100"#))
        #expect(book.contains(#"case "name": self.name = value as? String"#))
        let writer = try await files("library", ["library/Writer.swift"])[0]
        #expect(writer.contains(#"case "aliases": return EcoreValueArray(self.aliases.map { $0 as any EcoreValue })"#))
        #expect(writer.contains(#"case "aliases": self.aliases = (value as? EcoreValueArray)?.values.compactMap { $0 as? String } ?? []"#))
        #expect(writer.contains(#"case "aliases": return !self.aliases.isEmpty"#))
        let vehicle = try await files("swiftnames", ["swiftnames/Vehicle.swift"])[0]
        #expect(vehicle.contains(#"case "driver": self.driver = value as? Driver"#))
        #expect(vehicle.contains(#"case "kinds": self.kinds = (value as? EcoreValueArray)?.values.compactMap { $0 as? (any `Type`) } ?? []"#))
    }

    // MARK: - Other classifiers

    @Test("Enumerations are raw-value enumerations with aliases for repeated values")
    @MainActor
    func enumerations() async throws {
        let all = try await allFiles("enumerations")
        let colour = try #require(all["enumerations/Colour.swift"])
        #expect(colour.contains("public enum Colour: Int, Sendable, Codable, CaseIterable, EcoreValue {"))
        #expect(colour.contains("    case Amber = 1\n"))
        #expect(!colour.contains("    case Yellow"))
        #expect(colour.contains("    public static let Yellow: Colour = .Amber\n"))
        #expect(colour.contains(#"case "yellow": self = .Yellow"#))
        let mode = try #require(all["enumerations/Mode.swift"])
        #expect(mode.contains("    case `default` = 0\n"))
        #expect(mode.contains("    case __ = 3\n"))
        #expect(mode.contains(#"case .quote: return "say \"hi\"""#))
        let empty = try #require(all["enumerations/Empty.swift"])
        #expect(empty.contains("public enum Empty: Sendable, Codable, CaseIterable, EcoreValue {"))
    }

    @Test("Data types become type aliases")
    @MainActor
    func dataTypes() async throws {
        let all = try await allFiles("datatypes")
        #expect(all["datatypes/Count.swift"]?.contains("public typealias Count = Int\n") == true)
        #expect(all["datatypes/Stamp.swift"]?.contains("public typealias Stamp = Date\n") == true)
        #expect(all["datatypes/Hidden.swift"]?.contains("public typealias Hidden = String\n") == true)
        #expect(all["datatypes/Anything.swift"]?.contains("public typealias Anything = any EcoreValue\n") == true)
        #expect(all["datatypes/Stamp.swift"]?.contains("\nimport Foundation\n") == true)
    }

    @Test("The package description builds the Ecore package with its classes, features and opposites")
    @MainActor
    func packageDescription() async throws {
        let package = try await files("library", ["library/LibraryPackage.swift"])[0]
        #expect(package.contains("public static let shared = LibraryPackage()"))
        #expect(package.contains("public let ePackage: EPackage"))
        #expect(package.contains("public let eBook: EClass"))
        #expect(package.contains("public let eBookCategory: EEnum"))
        #expect(package.contains("public let eISBN: EDataType"))
        #expect(package.contains("public var factory: LibraryFactory { LibraryFactory.shared }"))
        #expect(package.contains(#"EEnumLiteral(name: "ScienceFiction", value: 1, literal: "ScienceFiction"),"#))
        #expect(package.contains("eSuperTypes: [class_Named, class_Lendable],"))
        #expect(package.contains("opposite: featureID_Writer_books,"))
        #expect(package.contains("container: true),"))
        #expect(package.contains(#"nsURI: "http://swift-modelling.org/test/library/1.0", nsPrefix: "lib","#))
        #expect(package.contains("lowerBound: 1, upperBound: 1,"))
        #expect(package.contains("lowerBound: 0, upperBound: -1,"))
        #expect(package.contains(#"defaultValueLiteral: "14","#))
    }

    @Test("A class named Package does not hide the package property of its description")
    @MainActor
    func packageNamedClass() async throws {
        let all = try await allFiles("swiftnames")
        let package = try #require(all["swiftnames/SwiftnamesPackage.swift"])
        #expect(package.contains("public let ePackage: EPackage"))
        #expect(!package.contains("public let ePackage: EClass"))
    }

    @Test("Operations of the model are not part of the generated code")
    @MainActor
    func operationsAreNotGenerated() async throws {
        let all = try await allFiles("swiftnames")
        #expect(all.values.allSatisfy { !$0.contains("func start") })
    }
}
