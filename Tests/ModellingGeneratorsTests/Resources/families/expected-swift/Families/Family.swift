//
//  Family.swift
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Family class.
///
/// Part of the Families package.
// @generated
public final class Family: EObject {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { FamiliesPackage.shared.eFamily }

    /// The values of the features of the object.
    // @generated
    private struct EStorage: Sendable {
        var lastName: String? = nil
        var father: Member? = nil
        var mother: Member? = nil
        var sons: [Member] = []
        var daughters: [Member] = []
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

    /// The lastName attribute.
    // @generated
    public var lastName: String? {
        get { eStorage.withLock { $0.lastName } }
        set { eStorage.withLock { $0.lastName = newValue } }
    }

    /// The father reference.
    // @generated
    public var father: Member? {
        get { eStorage.withLock { $0.father } }
        set {
            let previous = eStorage.withLock { values -> Member? in
                let old = values.father
                values.father = newValue
                return old
            }
            guard previous !== newValue else { return }
            if let previous, previous.familyFather === self { previous.familyFather = nil }
            if let newValue, newValue.familyFather !== self { newValue.familyFather = self }
        }
    }

    /// The mother reference.
    // @generated
    public var mother: Member? {
        get { eStorage.withLock { $0.mother } }
        set {
            let previous = eStorage.withLock { values -> Member? in
                let old = values.mother
                values.mother = newValue
                return old
            }
            guard previous !== newValue else { return }
            if let previous, previous.familyMother === self { previous.familyMother = nil }
            if let newValue, newValue.familyMother !== self { newValue.familyMother = self }
        }
    }

    /// The sons reference.
    // @generated
    public var sons: [Member] {
        get { eStorage.withLock { $0.sons } }
        set { eStorage.withLock { $0.sons = newValue } }
    }

    /// The daughters reference.
    // @generated
    public var daughters: [Member] {
        get { eStorage.withLock { $0.daughters } }
        set { eStorage.withLock { $0.daughters = newValue } }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Family, rhs: Family) -> Bool { lhs.id == rhs.id }

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
        case "lastName": return self.lastName
        case "father": return self.father
        case "mother": return self.mother
        case "sons": return EcoreValueArray(self.sons.map { $0 as any EcoreValue })
        case "daughters": return EcoreValueArray(self.daughters.map { $0 as any EcoreValue })
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
        case "lastName": self.lastName = value as? String
        case "father": self.father = value as? Member
        case "mother": self.mother = value as? Member
        case "sons": self.sons = (value as? EcoreValueArray)?.values.compactMap { $0 as? Member } ?? []
        case "daughters": self.daughters = (value as? EcoreValueArray)?.values.compactMap { $0 as? Member } ?? []
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
        case "lastName": return self.lastName != nil
        case "father": return self.father != nil
        case "mother": return self.mother != nil
        case "sons": return !self.sons.isEmpty
        case "daughters": return !self.daughters.isEmpty
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
