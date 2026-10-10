//
//  Member.swift
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Member class.
///
/// Part of the Families package.
// @generated
public final class Member: EObject {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { FamiliesPackage.shared.eMember }

    /// A reference that does not keep the object it refers to alive.
    // @generated
    private struct EWeakReference: Sendable {
        weak var object: (AnyObject & Sendable)?

        init(_ object: (AnyObject & Sendable)?) { self.object = object }
    }

    /// The values of the features of the object.
    // @generated
    private struct EStorage: Sendable {
        var firstName: String? = nil
        var familyFather = EWeakReference(nil)
        var familyMother = EWeakReference(nil)
        var familySon = EWeakReference(nil)
        var familyDaughter = EWeakReference(nil)
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

    /// The firstName attribute.
    // @generated
    public var firstName: String? {
        get { eStorage.withLock { $0.firstName } }
        set { eStorage.withLock { $0.firstName = newValue } }
    }

    /// The familyFather reference.
    // @generated
    public var familyFather: Family? {
        get { eStorage.withLock { $0.familyFather.object as? Family } }
        set {
            let previous = eStorage.withLock { values -> Family? in
                let old = values.familyFather.object as? Family
                values.familyFather = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            if let previous, previous.father === self { previous.father = nil }
            if let newValue, newValue.father !== self { newValue.father = self }
        }
    }

    /// The familyMother reference.
    // @generated
    public var familyMother: Family? {
        get { eStorage.withLock { $0.familyMother.object as? Family } }
        set {
            let previous = eStorage.withLock { values -> Family? in
                let old = values.familyMother.object as? Family
                values.familyMother = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            if let previous, previous.mother === self { previous.mother = nil }
            if let newValue, newValue.mother !== self { newValue.mother = self }
        }
    }

    /// The familySon reference.
    // @generated
    public var familySon: Family? {
        get { eStorage.withLock { $0.familySon.object as? Family } }
        set {
            let previous = eStorage.withLock { values -> Family? in
                let old = values.familySon.object as? Family
                values.familySon = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            previous?.sons.removeAll { $0 === self }
            if let newValue, !newValue.sons.contains(where: { $0 === self }) { newValue.sons.append(self) }
        }
    }

    /// The familyDaughter reference.
    // @generated
    public var familyDaughter: Family? {
        get { eStorage.withLock { $0.familyDaughter.object as? Family } }
        set {
            let previous = eStorage.withLock { values -> Family? in
                let old = values.familyDaughter.object as? Family
                values.familyDaughter = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            previous?.daughters.removeAll { $0 === self }
            if let newValue, !newValue.daughters.contains(where: { $0 === self }) { newValue.daughters.append(self) }
        }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Member, rhs: Member) -> Bool { lhs.id == rhs.id }

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
        case "firstName": return self.firstName
        case "familyFather": return self.familyFather
        case "familyMother": return self.familyMother
        case "familySon": return self.familySon
        case "familyDaughter": return self.familyDaughter
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
        case "firstName": self.firstName = value as? String
        case "familyFather": self.familyFather = value as? Family
        case "familyMother": self.familyMother = value as? Family
        case "familySon": self.familySon = value as? Family
        case "familyDaughter": self.familyDaughter = value as? Family
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
        case "firstName": return self.firstName != nil
        case "familyFather": return self.familyFather != nil
        case "familyMother": return self.familyMother != nil
        case "familySon": return self.familySon != nil
        case "familyDaughter": return self.familyDaughter != nil
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
