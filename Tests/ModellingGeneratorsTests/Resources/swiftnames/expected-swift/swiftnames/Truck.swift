//
//  Truck.swift
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Truck class.
///
/// Part of the swiftnames package.
// @generated
public final class Truck: EObject, Vehicle {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { SwiftnamesPackage.shared.eTruck }

    /// A reference that does not keep the object it refers to alive.
    // @generated
    private struct EWeakReference: Sendable {
        weak var object: (AnyObject & Sendable)?

        init(_ object: (AnyObject & Sendable)?) { self.object = object }
    }

    /// The values of the features of the object.
    // @generated
    private struct EStorage: Sendable {
        var name: String? = "say \"hi\"\n\\there"
        var `default`: String? = nil
        var `guard`: String? = nil
        var `class`: String? = nil
        var `operator`: Int = 0
        var `repeat`: Bool = false
        var `where`: String? = nil
        var `in`: String? = nil
        var `protocol`: String? = nil
        var id_: String? = nil
        var hash_: Int = 0
        var hue: Hue = .green
        var shades: [Hue] = []
        var driver = EWeakReference(nil)
        var kinds: [any `Type`] = []
        var wheels: [Wheel] = []
        var load: Double = 2.5
        var plate: String? = "N/A"
        var trailer = EWeakReference(nil)
        var towedBy = EWeakReference(nil)
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

    /// The name attribute.
    // @generated
    public var name: String? {
        get { eStorage.withLock { $0.name } }
        set { eStorage.withLock { $0.name = newValue } }
    }

    /// The default attribute.
    // @generated
    public var `default`: String? {
        get { eStorage.withLock { $0.`default` } }
        set { eStorage.withLock { $0.`default` = newValue } }
    }

    /// The guard attribute.
    // @generated
    public var `guard`: String? {
        get { eStorage.withLock { $0.`guard` } }
        set { eStorage.withLock { $0.`guard` = newValue } }
    }

    /// The class attribute.
    // @generated
    public var `class`: String? {
        get { eStorage.withLock { $0.`class` } }
        set { eStorage.withLock { $0.`class` = newValue } }
    }

    /// The operator attribute.
    // @generated
    public var `operator`: Int {
        get { eStorage.withLock { $0.`operator` } }
        set { eStorage.withLock { $0.`operator` = newValue } }
    }

    /// The repeat attribute.
    // @generated
    public var `repeat`: Bool {
        get { eStorage.withLock { $0.`repeat` } }
        set { eStorage.withLock { $0.`repeat` = newValue } }
    }

    /// The where attribute.
    // @generated
    public var `where`: String? {
        get { eStorage.withLock { $0.`where` } }
        set { eStorage.withLock { $0.`where` = newValue } }
    }

    /// The in attribute.
    // @generated
    public var `in`: String? {
        get { eStorage.withLock { $0.`in` } }
        set { eStorage.withLock { $0.`in` = newValue } }
    }

    /// The protocol attribute.
    // @generated
    public var `protocol`: String? {
        get { eStorage.withLock { $0.`protocol` } }
        set { eStorage.withLock { $0.`protocol` = newValue } }
    }

    /// The id attribute.
    // @generated
    public var id_: String? {
        get { eStorage.withLock { $0.id_ } }
        set { eStorage.withLock { $0.id_ = newValue } }
    }

    /// The hash attribute.
    // @generated
    public var hash_: Int {
        get { eStorage.withLock { $0.hash_ } }
        set { eStorage.withLock { $0.hash_ = newValue } }
    }

    /// The hue attribute.
    // @generated
    public var hue: Hue {
        get { eStorage.withLock { $0.hue } }
        set { eStorage.withLock { $0.hue = newValue } }
    }

    /// The shades attribute.
    // @generated
    public var shades: [Hue] {
        get { eStorage.withLock { $0.shades } }
        set { eStorage.withLock { $0.shades = newValue } }
    }

    /// The driver reference.
    // @generated
    public var driver: Driver? {
        get { eStorage.withLock { $0.driver.object as? Driver } }
        set {
            let previous = eStorage.withLock { values -> Driver? in
                let old = values.driver.object as? Driver
                values.driver = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            if let previous, previous.vehicle === self { previous.vehicle = nil }
            if let newValue, newValue.vehicle !== self { newValue.vehicle = self }
        }
    }

    /// The kinds reference.
    // @generated
    public var kinds: [any `Type`] {
        get { eStorage.withLock { $0.kinds } }
        set { eStorage.withLock { $0.kinds = newValue } }
    }

    /// The wheels reference.
    // @generated
    public var wheels: [Wheel] {
        get { eStorage.withLock { $0.wheels } }
        set { eStorage.withLock { $0.wheels = newValue } }
    }

    /// The load attribute.
    // @generated
    public var load: Double {
        get { eStorage.withLock { $0.load } }
        set { eStorage.withLock { $0.load = newValue } }
    }

    /// The plate attribute.
    // @generated
    public var plate: String? {
        get { eStorage.withLock { $0.plate } }
        set { eStorage.withLock { $0.plate = newValue } }
    }

    /// The trailer reference.
    // @generated
    public var trailer: Truck? {
        get { eStorage.withLock { $0.trailer.object as? Truck } }
        set {
            let previous = eStorage.withLock { values -> Truck? in
                let old = values.trailer.object as? Truck
                values.trailer = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            if let previous, previous.towedBy === self { previous.towedBy = nil }
            if let newValue, newValue.towedBy !== self { newValue.towedBy = self }
        }
    }

    /// The towedBy reference.
    // @generated
    public var towedBy: Truck? {
        get { eStorage.withLock { $0.towedBy.object as? Truck } }
        set {
            let previous = eStorage.withLock { values -> Truck? in
                let old = values.towedBy.object as? Truck
                values.towedBy = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            if let previous, previous.trailer === self { previous.trailer = nil }
            if let newValue, newValue.trailer !== self { newValue.trailer = self }
        }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Truck, rhs: Truck) -> Bool { lhs.id == rhs.id }

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
        case "name": return self.name
        case "default": return self.`default`
        case "guard": return self.`guard`
        case "class": return self.`class`
        case "operator": return self.`operator`
        case "repeat": return self.`repeat`
        case "where": return self.`where`
        case "in": return self.`in`
        case "protocol": return self.`protocol`
        case "id": return self.id_
        case "hash": return self.hash_
        case "hue": return self.hue
        case "shades": return EcoreValueArray(self.shades.map { $0 as any EcoreValue })
        case "driver": return self.driver
        case "kinds": return EcoreValueArray(self.kinds.map { $0 as any EcoreValue })
        case "wheels": return EcoreValueArray(self.wheels.map { $0 as any EcoreValue })
        case "load": return self.load
        case "plate": return self.plate
        case "trailer": return self.trailer
        case "towedBy": return self.towedBy
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
        case "name": self.name = (value as? String) ?? "say \"hi\"\n\\there"
        case "default": self.`default` = value as? String
        case "guard": self.`guard` = value as? String
        case "class": self.`class` = value as? String
        case "operator": self.`operator` = (value as? Int) ?? 0
        case "repeat": self.`repeat` = (value as? Bool) ?? false
        case "where": self.`where` = value as? String
        case "in": self.`in` = value as? String
        case "protocol": self.`protocol` = value as? String
        case "id": self.id_ = value as? String
        case "hash": self.hash_ = (value as? Int) ?? 0
        case "hue": self.hue = (value as? Hue) ?? .green
        case "shades": self.shades = (value as? EcoreValueArray)?.values.compactMap { $0 as? Hue } ?? []
        case "driver": self.driver = value as? Driver
        case "kinds": self.kinds = (value as? EcoreValueArray)?.values.compactMap { $0 as? (any `Type`) } ?? []
        case "wheels": self.wheels = (value as? EcoreValueArray)?.values.compactMap { $0 as? Wheel } ?? []
        case "load": self.load = (value as? Double) ?? 2.5
        case "plate": self.plate = (value as? String) ?? "N/A"
        case "trailer": self.trailer = value as? Truck
        case "towedBy": self.towedBy = value as? Truck
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
        case "name": return self.name != "say \"hi\"\n\\there"
        case "default": return self.`default` != nil
        case "guard": return self.`guard` != nil
        case "class": return self.`class` != nil
        case "operator": return self.`operator` != 0
        case "repeat": return self.`repeat` != false
        case "where": return self.`where` != nil
        case "in": return self.`in` != nil
        case "protocol": return self.`protocol` != nil
        case "id": return self.id_ != nil
        case "hash": return self.hash_ != 0
        case "hue": return self.hue != .green
        case "shades": return !self.shades.isEmpty
        case "driver": return self.driver != nil
        case "kinds": return !self.kinds.isEmpty
        case "wheels": return !self.wheels.isEmpty
        case "load": return self.load != 2.5
        case "plate": return self.plate != "N/A"
        case "trailer": return self.trailer != nil
        case "towedBy": return self.towedBy != nil
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
