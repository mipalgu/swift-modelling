//
//  Team.swift
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Team class.
///
/// Part of the organisation package.
// @generated
public final class Team: EObject {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { OrgPackage.shared.eTeam }

    /// A reference that does not keep the object it refers to alive.
    // @generated
    private struct EWeakReference: Sendable {
        weak var object: (AnyObject & Sendable)?

        init(_ object: (AnyObject & Sendable)?) { self.object = object }
    }

    /// The values of the features of the object.
    // @generated
    private struct EStorage: Sendable {
        var name: String? = nil
        var members: [Person] = []
        var leader = EWeakReference(nil)
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

    /// The members reference.
    // @generated
    public var members: [Person] {
        get { eStorage.withLock { $0.members } }
        set { eStorage.withLock { $0.members = newValue } }
    }

    /// The leader reference.
    // @generated
    public var leader: Person? {
        get { eStorage.withLock { $0.leader.object as? Person } }
        set { eStorage.withLock { $0.leader = EWeakReference(newValue) } }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Team, rhs: Team) -> Bool { lhs.id == rhs.id }

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
        case "members": return EcoreValueArray(self.members.map { $0 as any EcoreValue })
        case "leader": return self.leader
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
        case "name": self.name = value as? String
        case "members": self.members = (value as? EcoreValueArray)?.values.compactMap { $0 as? Person } ?? []
        case "leader": self.leader = value as? Person
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
        case "name": return self.name != nil
        case "members": return !self.members.isEmpty
        case "leader": return self.leader != nil
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
