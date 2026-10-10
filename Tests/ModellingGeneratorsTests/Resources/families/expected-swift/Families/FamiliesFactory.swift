//
//  FamiliesFactory.swift
//

import ECore
import EMFBase
import Foundation

/// The factory of the Families package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
public struct FamiliesFactory: Sendable {
    /// The shared factory of the package.
    // @generated
    public static let shared = FamiliesFactory()

    /// Creates a factory.
    // @generated
    public init() {}

    /// Creates a new Family object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createFamily() -> Family { Family() }

    /// Creates a new Member object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createMember() -> Member { Member() }

    /// Creates an object for a metaclass of the package.
    ///
    /// - Parameter eClass: The metaclass to create an object for.
    /// - Returns: A new object, or `nil` if the package has no class with instances of that name.
    // @generated
    public func create(_ eClass: EClass) -> (any EObject)? {
        switch eClass.name {
        case "Family": return createFamily()
        case "Member": return createMember()
        default: return nil
        }
    }
}
