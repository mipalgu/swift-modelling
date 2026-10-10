//
//  OrgFactory.swift
//

import ECore
import EMFBase
import Foundation

/// The factory of the organisation package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
public struct OrgFactory: Sendable {
    /// The shared factory of the package.
    // @generated
    public static let shared = OrgFactory()

    /// Creates a factory.
    // @generated
    public init() {}

    /// Creates a new Person object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createPerson() -> Person { Person() }

    /// Creates a new Team object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createTeam() -> Team { Team() }

    /// Creates a new Organisation object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createOrganisation() -> Organisation { Organisation() }

    /// Creates an object for a metaclass of the package.
    ///
    /// - Parameter eClass: The metaclass to create an object for.
    /// - Returns: A new object, or `nil` if the package has no class with instances of that name.
    // @generated
    public func create(_ eClass: EClass) -> (any EObject)? {
        switch eClass.name {
        case "Person": return createPerson()
        case "Team": return createTeam()
        case "Organisation": return createOrganisation()
        default: return nil
        }
    }
}
