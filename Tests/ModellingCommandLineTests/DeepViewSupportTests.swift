//
// DeepViewSupportTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import MultiLevel
import Testing

/// Tests for reading deep views from files and for the ATL helpers on the objects of deep views.
@Suite("Deep view support")
struct DeepViewSupportTests {
    /// A product catalogue of three levels.
    static let products = """
        Model Catalogue@2 {
          Node ProductType {
            gst@1 : double = 10.0;
            price : double = 0.0;
          }
        }

        Catalogue Bookshop {
          ProductType Book {
            gst = 0.0;
          }
          ProductType Magazine {}
        }

        Bookshop Shelf {
          Book manual {
            price = 35.0;
          }
          Magazine monthly {
            price = 9.5;
          }
        }

        """

    /// Writes a text file into a new scratch directory.
    ///
    /// - Parameters:
    ///   - text: The text of the file.
    ///   - name: The file name.
    /// - Returns: The location of the file.
    static func write(_ text: String, as name: String) throws -> URL {
        let url = try ScratchDirectory().url.appendingPathComponent(name)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// Removes the scratch directory of a file.
    ///
    /// - Parameter url: A file written by ``write(_:as:)``.
    static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    /// Calls a native helper on a receiver.
    ///
    /// - Parameters:
    ///   - name: The name of the helper.
    ///   - helpers: The helpers to choose from.
    ///   - receiver: The receiver of the call.
    /// - Returns: The value of the call.
    /// - Throws: An error if there is no such helper or its body throws.
    ///   - arguments: The arguments of the call (default: none).
    @MainActor
    static func call(
        _ name: String, in helpers: [ATLNativeHelper], on receiver: (any EcoreValue)?,
        with arguments: [(any EcoreValue)?] = []
    ) async throws -> (any EcoreValue)? {
        let helper = try #require(helpers.first { $0.name == name && $0.parameterTypes.count == arguments.count })
        return try await helper.body(receiver, arguments)
    }

    /// The names of the clabjects that the objects of a sequence stand for.
    ///
    /// - Parameters:
    ///   - value: The value of a helper, which should be a sequence.
    ///   - views: The views of the objects.
    /// - Returns: The names in order, or `nil` if the value is not a sequence.
    static func clabjectNames(_ value: (any EcoreValue)?, in views: DeepModelViews) -> [String]? {
        guard let sequence = value as? ATLCollectionValue, sequence.kind == .sequence else { return nil }
        return sequence.values.compactMap { views.clabject(of: $0)?.name }
    }

    @Test("reads the deep view of a level from a MetaDepth document")
    @MainActor
    func metaDepthDocument() async throws {
        let url = try Self.write(Self.products, as: "shop.mdepth")
        defer { Self.remove(url) }
        let loaded = try await MultiLevelSupport.views(ofFileAt: url, level: 0, in: ResourceSet())
        let views = try #require(loaded)
        #expect(views.view.level == 0)
        #expect(views.view.package.name == "Bookshop")
        #expect(await views.view.resource.getRootObjects().count == 2)
        #expect(try MultiLevelSupport.holdsMultiLevelModel(url))
    }

    @Test("reads the deep view of a level from an XMI document of linguistic instances")
    @MainActor
    func linguisticDocument() async throws {
        let model = try #require(MetaDepthReader.parse(Self.products).model)
        let url = try Self.write(try await LinguisticEncoding.xmi(of: model), as: "shop.xmi")
        defer { Self.remove(url) }
        #expect(try MultiLevelSupport.holdsMultiLevelModel(url))
        let loaded = try await MultiLevelSupport.views(ofFileAt: url, level: 1, in: ResourceSet())
        let views = try #require(loaded)
        #expect(views.view.package.name == "Catalogue")
        #expect(await views.view.resource.getRootObjects().count == 2)
    }

    @Test("leaves a file without a multi-level model to the caller")
    @MainActor
    func plainDocument() async throws {
        let url = try Self.write("<a:B xmlns:a=\"urn:example\"/>", as: "plain.xmi")
        defer { Self.remove(url) }
        #expect(!(try MultiLevelSupport.holdsMultiLevelModel(url)))
        #expect(try await MultiLevelSupport.views(ofFileAt: url, level: 0, in: ResourceSet()) == nil)
    }

    @Test("reports a level that the model does not have, with the path of the file")
    @MainActor
    func missingLevel() async throws {
        let url = try Self.write(Self.products, as: "shop.mdepth")
        defer { Self.remove(url) }
        let expected = DeepViewError(path: url.relativePath, reason: MultiLevelError.noSuchLevel(7).description)
        await #expect(throws: expected) {
            _ = try await MultiLevelSupport.views(ofFileAt: url, level: 7, in: ResourceSet())
        }
        #expect(expected.description == "\(url.relativePath): \(MultiLevelError.noSuchLevel(7).description)")
        #expect(expected.errorDescription == expected.description)
    }

    @Test("finds the clabject and the ontological type of an object of a view")
    @MainActor
    func clabjects() async throws {
        let url = try Self.write(Self.products, as: "shop.mdepth")
        defer { Self.remove(url) }
        let loaded = try await MultiLevelSupport.views(ofFileAt: url, level: 0, in: ResourceSet())
        let views = try #require(loaded)
        let objects = await views.view.resource.getRootObjects()
        let names = objects.compactMap { views.clabject(of: $0)?.name }
        #expect(names.sorted() == ["manual", "monthly"])
        let types = objects.compactMap { views.ontologicalClass(of: $0)?.name }
        #expect(types.sorted() == ["Book", "Magazine"])
        #expect(views.clabject(of: "manual") == nil)
        #expect(views.ontologicalClass(of: nil) == nil)
    }

    @Test("offers the deep services to ATL as helpers for OclAny")
    @MainActor
    func helpers() async throws {
        let url = try Self.write(Self.products, as: "shop.mdepth")
        defer { Self.remove(url) }
        let loaded = try await MultiLevelSupport.views(ofFileAt: url, level: 0, in: ResourceSet())
        let views = try #require(loaded)
        #expect(ATLDeepViewHelpers.helpers(for: []).isEmpty)
        let helpers = ATLDeepViewHelpers.helpers(for: [views])
        #expect(helpers.map(\.name) == ATLDeepViewHelpers.names)
        #expect(helpers.allSatisfy { $0.contextType == ATLDeepViewHelpers.contextType })
        #expect(helpers.prefix(6).allSatisfy { $0.parameterTypes.isEmpty })
        #expect(helpers.map(\.parameterTypes.count) == [0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1])

        let objects = await views.view.resource.getRootObjects()
        let manual = try #require(objects.first { views.clabject(of: $0)?.name == "manual" })
        let names = ATLDeepViewHelpers.names
        #expect(try await Self.call(names[0], in: helpers, on: manual) as? String == "manual")
        #expect((try await Self.call(names[1], in: helpers, on: manual) as? EClass)?.name == "Book")
        #expect(try await Self.call(names[2], in: helpers, on: manual) as? String == MultiLevelSyntax.nodeKeyword)
        #expect(try await Self.call(names[3], in: helpers, on: manual) as? Int == 0)
        #expect(try await Self.call(names[4], in: helpers, on: manual) as? Int == 0)
        for name in names.prefix(5) {
            #expect(try await Self.call(name, in: helpers, on: "manual") == nil)
        }
    }

    @Test("offers the deep types, the type at a level and slot values of an object to ATL")
    @MainActor
    func objectHelpers() async throws {
        let url = try Self.write(Self.products, as: "shop.mdepth")
        defer { Self.remove(url) }
        let loaded = try await MultiLevelSupport.views(ofFileAt: url, level: 0, in: ResourceSet())
        let views = try #require(loaded)
        let helpers = ATLDeepViewHelpers.helpers(for: [views])
        let objects = await views.view.resource.getRootObjects()
        let manual = try #require(objects.first { views.clabject(of: $0)?.name == "manual" })

        let types = try await Self.call("deepTypes", in: helpers, on: manual) as? ATLCollectionValue
        #expect(types?.kind == .sequence)
        #expect(types?.values.compactMap { ($0 as? EClass)?.name } == ["Book", "ProductType"])

        let book = try await Self.call("typeAtLevel", in: helpers, on: manual, with: [1])
        #expect(views.clabject(of: book)?.name == "Book")
        #expect(try await Self.call("typeAtLevel", in: helpers, on: manual, with: [5]) == nil)
        await #expect(throws: (any Error).self) {
            _ = try await Self.call("typeAtLevel", in: helpers, on: manual, with: ["one"])
        }

        #expect(try await Self.call("slotValue", in: helpers, on: manual, with: ["price"]) as? Double == 35.0)
        #expect(try await Self.call("slotValue", in: helpers, on: manual, with: ["gst"]) as? Double == 0.0)
        #expect(try await Self.call("slotValue", in: helpers, on: manual, with: ["colour"]) == nil)

        for type in ["Bookshop!Book", "Catalogue!ProductType", "ProductType"] {
            #expect(try await Self.call("isDeepInstanceOf", in: helpers, on: manual, with: [type]) as? Bool == true)
        }
        #expect(try await Self.call("isDeepInstanceOf", in: helpers, on: manual, with: ["Bookshop!Magazine"]) as? Bool == false)
        let magazineClabject = try #require(views.model.clabject(named: "Magazine"))
        let magazine = try #require(views.eClass(ofClabject: magazineClabject.id))
        #expect(try await Self.call("isDeepInstanceOf", in: helpers, on: manual, with: [magazine]) as? Bool == false)
        await #expect(throws: (any Error).self) {
            _ = try await Self.call("isDeepInstanceOf", in: helpers, on: manual, with: [42])
        }

        for (name, arguments) in [
            ("deepTypes", []), ("typeAtLevel", [1]), ("slotValue", ["price"]), ("isDeepInstanceOf", ["Book"]),
        ] as [(String, [(any EcoreValue)?])] {
            #expect(try await Self.call(name, in: helpers, on: "manual", with: arguments) == nil, "\(name)")
        }
    }

    @Test("offers the deep instances of a type to ATL")
    @MainActor
    func typeHelpers() async throws {
        let url = try Self.write(Self.products, as: "shop.mdepth")
        defer { Self.remove(url) }
        let loaded = try await MultiLevelSupport.views(ofFileAt: url, level: 0, in: ResourceSet())
        let views = try #require(loaded)
        let helpers = ATLDeepViewHelpers.helpers(for: [views])

        let all = try await Self.call("deepInstances", in: helpers, on: "Catalogue!ProductType")
        #expect(Self.clabjectNames(all, in: views) == ["Book", "Magazine", "manual", "monthly"])
        let bottom = try await Self.call("instancesAtLevel", in: helpers, on: "Bookshop!ProductType", with: [0])
        #expect(Self.clabjectNames(bottom, in: views) == ["manual", "monthly"])
        let bookClabject = try #require(views.model.clabject(named: "Book"))
        let book = try #require(views.eClass(ofClabject: bookClabject.id))
        let books = try await Self.call("deepInstances", in: helpers, on: book)
        #expect(Self.clabjectNames(books, in: views) == ["manual"])
        let none = try await Self.call("deepInstances", in: helpers, on: "Bookshop!Lamp")
        #expect(Self.clabjectNames(none, in: views) == [])

        #expect(try await Self.call("deepInstances", in: helpers, on: "ProductType") == nil)
        #expect(try await Self.call("deepInstances", in: helpers, on: 3) == nil)
        await #expect(throws: (any Error).self) {
            _ = try await Self.call("instancesAtLevel", in: helpers, on: "Bookshop!ProductType", with: [nil])
        }
    }
}
