//
//  Span.swift
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Span class.
///
/// Part of the bridge package.
// @generated
public final class Span: EObject {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { BridgePackage.shared.eSpan }

    /// A reference that does not keep the object it refers to alive.
    // @generated
    private struct EWeakReference: Sendable {
        weak var object: (AnyObject & Sendable)?

        init(_ object: (AnyObject & Sendable)?) { self.object = object }
    }

    /// The values of the features of the object.
    // @generated
    private struct EStorage: Sendable {
        var label: String? = nil
        var length: Double = 0.0
        var payload: (any EcoreValue)? = nil
        var supports: [any EObject] = []
        var next = EWeakReference(nil)
    }

    /// The values of the features, guarded by a lock.
    // @generated
    private let eStorage: Mutex<EStorage>

    /// Creates an object with all features at their defaults.
    ///
    /// - Parameter id: The unique identifier of the object; a new one by default.
    // @generated
    public init(id: EUUID = EUUID()) {
        self.id = id
        self.eStorage = Mutex(EStorage())
    }

    /// The label attribute.
    // @generated
    public var label: String? {
        get { eStorage.withLock { $0.label } }
        set { eStorage.withLock { $0.label = newValue } }
    }

    /// The length attribute.
    // @generated
    public var length: Double {
        get { eStorage.withLock { $0.length } }
        set { eStorage.withLock { $0.length = newValue } }
    }

    /// The payload attribute.
    // @generated
    public var payload: (any EcoreValue)? {
        get { eStorage.withLock { $0.payload } }
        set { eStorage.withLock { $0.payload = newValue } }
    }

    /// The supports reference.
    // @generated
    public var supports: [any EObject] {
        get { eStorage.withLock { $0.supports } }
        set { eStorage.withLock { $0.supports = newValue } }
    }

    /// The next reference.
    // @generated
    public var next: Span? {
        get { eStorage.withLock { $0.next.object as? Span } }
        set { eStorage.withLock { $0.next = EWeakReference(newValue) } }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Span, rhs: Span) -> Bool { lhs.id == rhs.id }

    /// Hashes the identifier of the object.
    ///
    /// - Parameter hasher: The hasher to combine the identifier into.
    // @generated
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Reflectively retrieves the value of a feature.
    ///
    /// - Parameter feature: The structural feature whose value to retrieve.
    /// - Returns: The current value of the feature, or `nil` if the class has no such feature.
    // @generated
    public func eGet(_ feature: some EStructuralFeature) -> (any EcoreValue)? {
        switch feature.name {
        case "label": return self.label
        case "length": return self.length
        case "payload": return self.payload
        case "supports": return EcoreValueArray(self.supports.map { $0 as any EcoreValue })
        case "next": return self.next
        default: return nil
        }
    }

    /// Reflectively sets the value of a feature.
    ///
    /// - Parameters:
    ///   - feature: The structural feature to modify.
    ///   - value: The new value; `nil`, or a value of the wrong type, resets the feature to its default.
    // @generated
    public func eSet(_ feature: some EStructuralFeature, _ value: (any EcoreValue)?) {
        switch feature.name {
        case "label": self.label = value as? String
        case "length": self.length = (value as? Double) ?? 0.0
        case "payload": self.payload = value
        case "supports": self.supports = (value as? EcoreValueArray)?.values.compactMap { $0 as? (any EObject) } ?? []
        case "next": self.next = value as? Span
        default: break
        }
    }

    /// Checks whether a feature differs from its default value.
    ///
    /// - Parameter feature: The structural feature to check.
    /// - Returns: `true` if the feature has been set to something other than its default.
    // @generated
    public func eIsSet(_ feature: some EStructuralFeature) -> Bool {
        switch feature.name {
        case "label": return self.label != nil
        case "length": return self.length != 0.0
        case "payload": return self.payload != nil
        case "supports": return !self.supports.isEmpty
        case "next": return self.next != nil
        default: return false
        }
    }

    /// Returns a feature to its default value.
    ///
    /// - Parameter feature: The structural feature to unset.
    // @generated
    public func eUnset(_ feature: some EStructuralFeature) {
        eSet(feature, nil)
    }
}
