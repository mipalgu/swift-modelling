//
//  Canvas.swift
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Canvas class.
///
/// Part of the classes package.
// @generated
public final class Canvas: EObject {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { ClassesPackage.shared.eCanvas }

    /// A reference that does not keep the object it refers to alive.
    // @generated
    private struct EWeakReference: Sendable {
        weak var object: (AnyObject & Sendable)?

        init(_ object: (AnyObject & Sendable)?) { self.object = object }
    }

    /// The values of the features of the object.
    // @generated
    private struct EStorage: Sendable {
        var shapes: [any Shape] = []
        var background: (any Shape)? = nil
        var favourites: [any Shape] = []
        var selected = EWeakReference(nil)
        var primary = EWeakReference(nil)
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

    /// The shapes reference.
    // @generated
    public var shapes: [any Shape] {
        get { eStorage.withLock { $0.shapes } }
        set { eStorage.withLock { $0.shapes = newValue } }
    }

    /// The background reference.
    // @generated
    public var background: (any Shape)? {
        get { eStorage.withLock { $0.background } }
        set { eStorage.withLock { $0.background = newValue } }
    }

    /// The favourites reference.
    // @generated
    public var favourites: [any Shape] {
        get { eStorage.withLock { $0.favourites } }
        set { eStorage.withLock { $0.favourites = newValue } }
    }

    /// The selected reference.
    // @generated
    public var selected: (any Shape)? {
        get { eStorage.withLock { $0.selected.object as? (any Shape) } }
        set { eStorage.withLock { $0.selected = EWeakReference(newValue) } }
    }

    /// The primary reference.
    // @generated
    public var primary: (any Shape)? {
        get { eStorage.withLock { $0.primary.object as? (any Shape) } }
        set { eStorage.withLock { $0.primary = EWeakReference(newValue) } }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Canvas, rhs: Canvas) -> Bool { lhs.id == rhs.id }

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
        case "shapes": return EcoreValueArray(self.shapes.map { $0 as any EcoreValue })
        case "background": return self.background
        case "favourites": return EcoreValueArray(self.favourites.map { $0 as any EcoreValue })
        case "selected": return self.selected
        case "primary": return self.primary
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
        case "shapes": self.shapes = (value as? EcoreValueArray)?.values.compactMap { $0 as? (any Shape) } ?? []
        case "background": self.background = value as? (any Shape)
        case "favourites": self.favourites = (value as? EcoreValueArray)?.values.compactMap { $0 as? (any Shape) } ?? []
        case "selected": self.selected = value as? (any Shape)
        case "primary": self.primary = value as? (any Shape)
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
        case "shapes": return !self.shapes.isEmpty
        case "background": return self.background != nil
        case "favourites": return !self.favourites.isEmpty
        case "selected": return self.selected != nil
        case "primary": return self.primary != nil
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
