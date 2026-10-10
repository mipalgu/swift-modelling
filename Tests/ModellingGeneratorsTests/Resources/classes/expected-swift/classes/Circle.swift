//
//  Circle.swift
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Circle class.
///
/// Part of the classes package.
// @generated
public final class Circle: EObject, Shape, Named {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { ClassesPackage.shared.eCircle }

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
        var visible: Bool = true
        var weight: Double = 1.5
        var tags: [String] = []
        var levels: [Int] = []
        var colour: Colour = .Green
        var description: String? = nil
        var canvas = EWeakReference(nil)
        var name: String? = nil
        var radius: Double = 0.0
        var filled: Bool = false
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

    /// The label of the shape.
    // @generated
    public var label: String? {
        get { eStorage.withLock { $0.label } }
        set { eStorage.withLock { $0.label = newValue } }
    }

    /// The visible attribute.
    // @generated
    public var visible: Bool {
        get { eStorage.withLock { $0.visible } }
        set { eStorage.withLock { $0.visible = newValue } }
    }

    /// The weight attribute.
    // @generated
    public var weight: Double {
        get { eStorage.withLock { $0.weight } }
        set { eStorage.withLock { $0.weight = newValue } }
    }

    /// The tags attribute.
    // @generated
    public var tags: [String] {
        get { eStorage.withLock { $0.tags } }
        set { eStorage.withLock { $0.tags = newValue } }
    }

    /// The levels attribute.
    // @generated
    public var levels: [Int] {
        get { eStorage.withLock { $0.levels } }
        set { eStorage.withLock { $0.levels = newValue } }
    }

    /// The colour attribute.
    // @generated
    public var colour: Colour {
        get { eStorage.withLock { $0.colour } }
        set { eStorage.withLock { $0.colour = newValue } }
    }

    /// The description attribute.
    // @generated
    public var description: String? {
        get { eStorage.withLock { $0.description } }
        set { eStorage.withLock { $0.description = newValue } }
    }

    /// The canvas reference.
    // @generated
    public var canvas: Canvas? {
        get { eStorage.withLock { $0.canvas.object as? Canvas } }
        set {
            let previous = eStorage.withLock { values -> Canvas? in
                let old = values.canvas.object as? Canvas
                values.canvas = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            previous?.shapes.removeAll { $0 === self }
            if let newValue, !newValue.shapes.contains(where: { $0 === self }) { newValue.shapes.append(self) }
        }
    }

    /// The name attribute.
    // @generated
    public var name: String? {
        get { eStorage.withLock { $0.name } }
        set { eStorage.withLock { $0.name = newValue } }
    }

    /// The radius attribute.
    // @generated
    public var radius: Double {
        get { eStorage.withLock { $0.radius } }
        set { eStorage.withLock { $0.radius = newValue } }
    }

    /// The filled attribute.
    // @generated
    public var filled: Bool {
        get { eStorage.withLock { $0.filled } }
        set { eStorage.withLock { $0.filled = newValue } }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Circle, rhs: Circle) -> Bool { lhs.id == rhs.id }

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
        case "visible": return self.visible
        case "weight": return self.weight
        case "tags": return EcoreValueArray(self.tags.map { $0 as any EcoreValue })
        case "levels": return EcoreValueArray(self.levels.map { $0 as any EcoreValue })
        case "colour": return self.colour
        case "description": return self.description
        case "canvas": return self.canvas
        case "name": return self.name
        case "radius": return self.radius
        case "filled": return self.filled
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
        case "visible": self.visible = (value as? Bool) ?? true
        case "weight": self.weight = (value as? Double) ?? 1.5
        case "tags": self.tags = (value as? EcoreValueArray)?.values.compactMap { $0 as? String } ?? []
        case "levels": self.levels = (value as? EcoreValueArray)?.values.compactMap { $0 as? Int } ?? []
        case "colour": self.colour = (value as? Colour) ?? .Green
        case "description": self.description = value as? String
        case "canvas": self.canvas = value as? Canvas
        case "name": self.name = value as? String
        case "radius": self.radius = (value as? Double) ?? 0.0
        case "filled": self.filled = (value as? Bool) ?? false
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
        case "visible": return self.visible != true
        case "weight": return self.weight != 1.5
        case "tags": return !self.tags.isEmpty
        case "levels": return !self.levels.isEmpty
        case "colour": return self.colour != .Green
        case "description": return self.description != nil
        case "canvas": return self.canvas != nil
        case "name": return self.name != nil
        case "radius": return self.radius != 0.0
        case "filled": return self.filled != false
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
