//
//  Driver.swift
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Driver class.
///
/// Part of the swiftnames package.
// @generated
public final class Driver: EObject {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { SwiftnamesPackage.shared.eDriver }

    /// A reference that does not keep the object it refers to alive.
    // @generated
    private struct EWeakReference: Sendable {
        weak var object: (AnyObject & Sendable)?

        init(_ object: (AnyObject & Sendable)?) { self.object = object }
    }

    /// The values of the features of the object.
    // @generated
    private struct EStorage: Sendable {
        var vehicle = EWeakReference(nil)
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

    /// The vehicle reference.
    // @generated
    public var vehicle: (any Vehicle)? {
        get { eStorage.withLock { $0.vehicle.object as? (any Vehicle) } }
        set {
            let previous = eStorage.withLock { values -> (any Vehicle)? in
                let old = values.vehicle.object as? (any Vehicle)
                values.vehicle = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            if let previous, previous.driver === self { previous.driver = nil }
            if let newValue, newValue.driver !== self { newValue.driver = self }
        }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Driver, rhs: Driver) -> Bool { lhs.id == rhs.id }

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
        case "vehicle": return self.vehicle
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
        case "vehicle": self.vehicle = value as? (any Vehicle)
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
        case "vehicle": return self.vehicle != nil
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
