//
// ModelCatalogue.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// Every object of a model, in the order of its containment tree.
///
/// The catalogue walks the containment references from the root objects of a model, so it
/// lists every object of the document, however deeply nested, once. Each object has a location
/// in the fragment syntax of the Eclipse Modeling Framework, such as `//@employees.0`, that
/// stays the same from one run to the next. Objects that a resource holds but no root contains
/// follow the contained objects.
struct ModelCatalogue: Sendable {
    /// One object of the model and where it is.
    struct Entry: Sendable {
        /// The object.
        let object: DynamicEObject

        /// The fragment that locates the object within its document.
        let location: String

        /// The identifier of the container, or `nil` for a root object.
        let container: EUUID?

        /// The name of the containment reference that holds the object, or `nil` for a root.
        let feature: String?

        /// How many containers lie between the object and its root; zero for a root.
        let depth: Int
    }

    /// The objects in document order: each object is followed by everything it contains.
    let entries: [Entry]

    /// The identifiers of the root objects, in document order.
    let roots: [EUUID]

    /// The position of each object in ``entries``.
    private let positions: [EUUID: Int]

    /// The canonical classes of the describing metamodels, by identifier.
    let classes: [EUUID: EClass]

    /// The resource set that resolves references into other documents.
    let resourceSet: ResourceSet

    /// Collects the objects of a model document.
    ///
    /// - Parameter document: The model document.
    /// - Returns: The catalogue of its objects.
    static func build(for document: ModelDocument) async -> ModelCatalogue {
        let resource = document.resource
        let rootObjects = await resource.getRootObjects().compactMap { $0 as? DynamicEObject }
        var entries: [Entry] = []
        var seen: Set<EUUID> = []
        let singleRoot = rootObjects.count == 1
        for (index, root) in rootObjects.enumerated() {
            let location = singleRoot
                ? ModelVocabulary.rootFragment : ModelVocabulary.segmentSeparator + "\(index)"
            await collect(root, location: location, container: nil, feature: nil, depth: 0,
                          in: resource, into: &entries, seen: &seen)
        }
        for case let object as DynamicEObject in await resource.getAllObjects() where !seen.contains(object.id) {
            await collect(object, location: ModelVocabulary.uncontainedLocation, container: nil, feature: nil,
                          depth: 0, in: resource, into: &entries, seen: &seen)
        }
        var positions: [EUUID: Int] = [:]
        for (index, entry) in entries.enumerated() { positions[entry.object.id] = index }
        return ModelCatalogue(
            entries: entries, roots: rootObjects.map(\.id), positions: positions,
            classes: MetamodelCatalogue.classesByIdentifier(in: document.describingPackages),
            resourceSet: document.resourceSet)
    }

    /// Adds an object and, depth first, everything it contains.
    private static func collect(
        _ object: DynamicEObject, location: String, container: EUUID?, feature: String?, depth: Int,
        in resource: Resource, into entries: inout [Entry], seen: inout Set<EUUID>
    ) async {
        guard seen.insert(object.id).inserted else { return }
        entries.append(Entry(object: object, location: location, container: container, feature: feature, depth: depth))
        for reference in MetamodelCatalogue.references(of: object.eClass) where reference.containment {
            let children = await objects(in: object.eGet(reference), resource: resource)
            for (index, child) in children.enumerated() {
                let step = ModelVocabulary.featureStepPrefix + reference.name
                    + (reference.isMany ? ModelVocabulary.indexSeparator + "\(index)" : "")
                await collect(child, location: location + ModelVocabulary.segmentSeparator + step, container: object.id,
                              feature: reference.name, depth: depth + 1, in: resource, into: &entries, seen: &seen)
            }
        }
    }

    /// The objects that a containment value holds.
    private static func objects(in value: (any EcoreValue)?, resource: Resource) async -> [DynamicEObject] {
        var result: [DynamicEObject] = []
        for element in ValueElements.of(value) {
            if let id = element as? EUUID, let object = await resource.resolve(id) as? DynamicEObject {
                result.append(object)
            } else if let object = element as? DynamicEObject {
                result.append(await resource.resolve(object.id) as? DynamicEObject ?? object)
            }
        }
        return result
    }

    /// The entry of an object of the model, if the catalogue holds it.
    ///
    /// - Parameter id: The identifier of the object.
    /// - Returns: The entry, or `nil` if the object is not part of the model.
    func entry(for id: EUUID) -> Entry? {
        positions[id].map { entries[$0] }
    }

    /// The entries that a container holds directly, in document order.
    ///
    /// - Parameter id: The identifier of the container.
    /// - Returns: The contained entries.
    func children(of id: EUUID) -> [Entry] {
        entries.filter { $0.container == id }
    }

    /// The canonical class of an object, preferring the definition of a describing metamodel.
    ///
    /// - Parameter object: The object.
    /// - Returns: The class.
    func eClass(of object: DynamicEObject) -> EClass {
        classes[object.eClass.id] ?? object.eClass
    }

    /// The objects whose class is a given class or one of its subclasses.
    ///
    /// - Parameter className: The name of the class, matched without regard to case.
    /// - Returns: The matching entries in document order.
    func entries(ofClassNamed className: String) -> [Entry] {
        let wanted = className.lowercased()
        return entries.filter { entry in
            let eClass = self.eClass(of: entry.object)
            return eClass.name.lowercased() == wanted
                || eClass.eAllSuperTypes.contains { $0.name.lowercased() == wanted }
        }
    }

    /// The number of objects of each class, in alphabetical order of the class names.
    var classCounts: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for entry in entries { counts[eClass(of: entry.object).name, default: 0] += 1 }
        return counts.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    /// The classes of the objects, once each, in alphabetical order of their names.
    var instantiatedClasses: [EClass] {
        var found: [String: EClass] = [:]
        for entry in entries {
            let eClass = self.eClass(of: entry.object)
            found[eClass.name] = found[eClass.name] ?? eClass
        }
        return found.keys.sorted().compactMap { found[$0] }
    }

    // MARK: - Descriptions

    /// A short description of an object: its class and the value that names it.
    ///
    /// - Parameter object: The object.
    /// - Returns: For example `Employee 'Alice Johnson'`, or the class name alone if no feature
    ///   names the object.
    func label(of object: DynamicEObject) -> String {
        let className = eClass(of: object).name
        guard let name = ObjectNaming.name(of: object, eClass: eClass(of: object)) else { return className }
        return "\(className) '\(name)'"
    }

    /// A description of an object together with its location.
    ///
    /// - Parameter object: The object.
    /// - Returns: For example `Employee 'Alice Johnson' (//@employees.0)`.
    func labelWithLocation(of object: DynamicEObject) -> String {
        guard let location = entry(for: object.id)?.location else { return label(of: object) }
        return "\(label(of: object)) (\(location))"
    }

    /// Describes the objects that a reference value refers to.
    ///
    /// Objects of the model are described with their location. A reference into another
    /// document is resolved through the resource set, loading the document if needed, and
    /// described together with that document; a reference that cannot be resolved is shown
    /// as its URI.
    ///
    /// - Parameter value: The value of a reference.
    /// - Returns: One description for each referenced object.
    func describeTargets(of value: (any EcoreValue)?) async -> [String] {
        var result: [String] = []
        for element in ValueElements.of(value) {
            result.append(await describeTarget(element))
        }
        return result
    }

    /// Describes one referenced object.
    private func describeTarget(_ element: any EcoreValue) async -> String {
        switch element {
        case let id as EUUID:
            if let entry = entry(for: id) { return labelWithLocation(of: entry.object) }
            if let found = await resourceSet.resolve(id), let dynamic = found.object as? DynamicEObject {
                return "\(label(of: dynamic)) in \(Self.documentName(of: found.resource))"
            }
            return id.uuidString
        case let object as DynamicEObject:
            if let entry = entry(for: object.id) { return labelWithLocation(of: entry.object) }
            return label(of: object)
        case let proxy as ResourceProxy:
            let text = Self.text(of: proxy)
            if let object = await proxy.resolveObject(in: resourceSet) as? DynamicEObject {
                return "\(label(of: object)) in \(text)"
            }
            return "\(text) (unresolved)"
        default:
            return ValueText.describe(element)
        }
    }

    /// The text of a reference into another document: the file name of the document and the
    /// fragment that names the object within it.
    ///
    /// - Parameter proxy: The reference.
    /// - Returns: For example `SharedDeps.xmi#/0`.
    static func text(of proxy: ResourceProxy) -> String {
        documentName(of: proxy.uri) + ModelVocabulary.fragmentSeparator + proxy.fragment
    }

    /// The file name of a document URI, or the URI itself if it names no file.
    private static func documentName(of uri: String) -> String {
        guard let url = URL(string: uri), !url.lastPathComponent.isEmpty else { return uri }
        return url.lastPathComponent
    }

    /// The file name of the document that a resource was read from.
    private static func documentName(of resource: Resource) -> String {
        documentName(of: resource.uri)
    }
}

/// Finds the value that names an object.
enum ObjectNaming {
    /// The value that names an object, if it has one.
    ///
    /// The value is that of the first feature of ``ModelVocabulary/labelFeatures`` that the
    /// object sets, else that of its identifying attribute, else that of its first single-valued
    /// string attribute.
    ///
    /// - Parameters:
    ///   - object: The object.
    ///   - eClass: The canonical class of the object.
    /// - Returns: The text of the value, or `nil` if no feature names the object.
    static func name(of object: DynamicEObject, eClass: EClass) -> String? {
        for feature in ModelVocabulary.labelFeatures {
            if let text = text(of: object.eGet(feature)) { return text }
        }
        let attributes = MetamodelCatalogue.attributes(of: eClass)
        if let id = attributes.first(where: \.isID), let text = text(of: object.eGet(id.name)) { return text }
        for attribute in attributes where !attribute.isMany && attribute.eType.name == EcoreDataType.eString.rawValue {
            if let text = text(of: object.eGet(attribute.name)) { return text }
        }
        return nil
    }

    /// The text of a single scalar value, if it is not empty.
    private static func text(of value: (any EcoreValue)?) -> String? {
        guard let value, !(value is EUUID), !(value is ResourceProxy), ValueElements.isScalar(value) else { return nil }
        let text = ValueText.plain(value)
        return text.isEmpty ? nil : text
    }
}

/// Splits feature values into their elements.
enum ValueElements {
    /// The elements of a value: those of a list, or the value itself.
    ///
    /// - Parameter value: A feature value.
    /// - Returns: The elements, or none for `nil`.
    static func of(_ value: (any EcoreValue)?) -> [any EcoreValue] {
        guard let value else { return [] }
        if let array = value as? EcoreValueArray { return array.values }
        if let array = value as? [EUUID] { return array }
        if let array = value as? [ResourceProxy] { return array }
        if let array = value as? [any EcoreValue] { return array }
        return [value]
    }

    /// Whether a value is a single value rather than a list.
    ///
    /// - Parameter value: A feature value.
    /// - Returns: `false` for lists, `true` otherwise.
    static func isScalar(_ value: any EcoreValue) -> Bool {
        !(value is EcoreValueArray) && !(value is [any EcoreValue])
    }
}

/// Writes feature values as text.
enum ValueText {
    /// The text of a value without quotation marks.
    ///
    /// - Parameter value: The value.
    /// - Returns: Its text.
    static func plain(_ value: any EcoreValue) -> String {
        switch value {
        case let text as String: return text
        case let date as Date: return ISO8601DateFormatter().string(from: date)
        default: return String(describing: value)
        }
    }

    /// The text of an attribute value as a description shows it.
    ///
    /// Strings are quoted, lists are written in brackets and long texts are shortened.
    ///
    /// - Parameter value: The value.
    /// - Returns: Its description.
    static func describe(_ value: (any EcoreValue)?) -> String {
        guard let value else { return "null" }
        if !ValueElements.isScalar(value) {
            return "[" + ValueElements.of(value).map { describe($0) }.joined(separator: ", ") + "]"
        }
        let text = shortened(plain(value))
        return value is String ? "\"\(text)\"" : text
    }

    /// The text of an attribute value, writing enumeration literals without quotation marks.
    ///
    /// - Parameters:
    ///   - value: The value.
    ///   - attribute: The attribute that holds the value.
    /// - Returns: Its description.
    static func describe(_ value: (any EcoreValue)?, of attribute: EAttribute) -> String {
        guard attribute.eType is EEnum else { return describe(value) }
        if let literal = value as? String { return literal }
        if let value, !ValueElements.isScalar(value) {
            return "[" + ValueElements.of(value).map { describe($0, of: attribute) }.joined(separator: ", ") + "]"
        }
        return describe(value)
    }

    /// A text shortened to ``ModelVocabulary/maximumValueLength`` characters.
    private static func shortened(_ text: String) -> String {
        guard text.count > ModelVocabulary.maximumValueLength else { return text }
        return String(text.prefix(ModelVocabulary.maximumValueLength)) + ModelVocabulary.ellipsis
    }
}
