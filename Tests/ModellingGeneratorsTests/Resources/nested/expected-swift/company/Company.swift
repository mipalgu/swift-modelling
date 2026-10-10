//
//  Company.swift
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Company class.
///
/// Part of the company package.
// @generated
public final class Company: EObject {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { CompanyPackage.shared.eCompany }

    /// The values of the features of the object.
    // @generated
    private struct EStorage: Sendable {
        var name: String? = nil
        var staff: [Employee] = []
        var projects: [Project] = []
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

    /// The staff reference.
    // @generated
    public var staff: [Employee] {
        get { eStorage.withLock { $0.staff } }
        set { eStorage.withLock { $0.staff = newValue } }
    }

    /// The projects reference.
    // @generated
    public var projects: [Project] {
        get { eStorage.withLock { $0.projects } }
        set { eStorage.withLock { $0.projects = newValue } }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Company, rhs: Company) -> Bool { lhs.id == rhs.id }

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
        case "staff": return EcoreValueArray(self.staff.map { $0 as any EcoreValue })
        case "projects": return EcoreValueArray(self.projects.map { $0 as any EcoreValue })
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
        case "staff": self.staff = (value as? EcoreValueArray)?.values.compactMap { $0 as? Employee } ?? []
        case "projects": self.projects = (value as? EcoreValueArray)?.values.compactMap { $0 as? Project } ?? []
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
        case "staff": return !self.staff.isEmpty
        case "projects": return !self.projects.isEmpty
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
