//
// ValueFormatter.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// Formats parameter values and model objects for the reader.
///
/// An object prints as the name of its class followed by its label in parentheses, as in
/// `Bin(A)`, or as the name of its class alone if it has no label. The label is the value of
/// its single-valued attribute called `name` (ignoring case) if the class has one, else of its
/// first single-valued text attribute, else of its first single-valued attribute. Text prints
/// in double quotes, other values as they are, and an absent value as `null`.
struct ValueFormatter: Sendable {
    /// Finds the object that an identity stands for, if it still exists.
    let resolve: @Sendable (EUUID) -> (any EObject)?

    /// Creates a formatter.
    ///
    /// - Parameter resolve: Finds the object that an identity stands for, if it exists.
    init(resolve: @escaping @Sendable (EUUID) -> (any EObject)?) {
        self.resolve = resolve
    }

    /// Creates a formatter for the objects of a model as it is now.
    ///
    /// - Parameter resource: The resource that holds the model.
    /// - Returns: A formatter that resolves identities among the objects of the resource.
    static func current(_ resource: Resource) async -> ValueFormatter {
        let objects = await resource.getAllObjects()
        var byIdentity: [EUUID: any EObject] = [:]
        for object in objects { byIdentity[object.id] = object }
        let index = byIdentity
        return ValueFormatter { index[$0] }
    }

    /// Creates a formatter for the objects of a snapshot of a model.
    ///
    /// - Parameter snapshot: The snapshot.
    /// - Returns: A formatter that resolves identities among the objects of the snapshot.
    static func snapshot(_ snapshot: ResourceSnapshot) -> ValueFormatter {
        ValueFormatter { snapshot.object(id: $0) }
    }

    /// Formats a value.
    ///
    /// - Parameter value: The value, or `nil` for an absent value.
    /// - Returns: The text of the value.
    func format(_ value: (any EcoreValue)?) -> String {
        typealias Display = SwiftHenshinVocabulary.Display
        guard let value else { return Display.null }
        switch value {
        case let text as String:
            return Display.quote + text + Display.quote
        case let identity as EUUID:
            return resolve(identity).map(Self.describe) ?? Display.deleted
        case let object as any EObject:
            return Self.describe(object)
        default:
            return String(describing: value)
        }
    }

    /// Formats the parameter values of an application, sorted by name.
    ///
    /// - Parameter values: The values by parameter name.
    /// - Returns: One `name=value` text per parameter, in the order of their names.
    func bindings(_ values: [String: any EcoreValue]) -> [String] {
        values.keys.sorted().map { $0 + SwiftHenshinVocabulary.Display.binding + format(values[$0]) }
    }

    /// The name of the class of an object followed by its label, if it has one.
    ///
    /// - Parameter object: The object.
    /// - Returns: The text, such as `Bin(A)` or `Bin`.
    static func describe(_ object: any EObject) -> String {
        typealias Display = SwiftHenshinVocabulary.Display
        let className = object.eClass.name
        guard let label = label(of: object) else { return className }
        return className + Display.labelOpening + label + Display.labelClosing
    }

    /// The label of an object.
    ///
    /// - Parameter object: The object.
    /// - Returns: The value of its label attribute as text, or `nil` if its class has no
    ///   label attribute or the object does not set it.
    static func label(of object: any EObject) -> String? {
        guard let eClass = object.eClass as? EClass, let attribute = labelAttribute(of: eClass),
            let value = object.eGet(attribute)
        else { return nil }
        return (value as? String) ?? String(describing: value)
    }

    /// The attribute whose value labels the objects of a class.
    ///
    /// - Parameter eClass: The class.
    /// - Returns: The single-valued attribute called `name` (ignoring case), else the first
    ///   single-valued text attribute, else the first single-valued attribute, or `nil` if the
    ///   class has no single-valued attribute.
    static func labelAttribute(of eClass: EClass) -> EAttribute? {
        let candidates = eClass.allAttributes.filter { !$0.isMany }
        if let named = candidates.first(where: {
            $0.name.caseInsensitiveCompare(SwiftHenshinVocabulary.Display.labelAttributeName) == .orderedSame
        }) {
            return named
        }
        let text = EcoreDataType.eString.rawValue
        return candidates.first { $0.eType.name == text } ?? candidates.first
    }
}
