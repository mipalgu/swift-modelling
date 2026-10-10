//
//  SwiftnamesFactory.swift
//

import ECore
import EMFBase
import Foundation

/// The factory of the swiftnames package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
public struct SwiftnamesFactory: Sendable {
    /// The shared factory of the package.
    // @generated
    public static let shared = SwiftnamesFactory()

    /// Creates a factory.
    // @generated
    public init() {}

    /// Creates a new Vehicle object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createVehicle() -> VehicleImpl { VehicleImpl() }

    /// Creates a new Truck object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createTruck() -> Truck { Truck() }

    /// Creates a new Driver object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createDriver() -> Driver { Driver() }

    /// Creates a new Date object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createDate() -> Date_ { Date_() }

    /// Creates a new Package object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createPackage() -> Package { Package() }

    /// Creates a new Values object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createValues() -> Values { Values() }

    /// Creates an object for a metaclass of the package.
    ///
    /// - Parameter eClass: The metaclass to create an object for.
    /// - Returns: A new object, or `nil` if the package has no class with instances of that name.
    // @generated
    public func create(_ eClass: EClass) -> (any EObject)? {
        switch eClass.name {
        case "Vehicle": return createVehicle()
        case "Truck": return createTruck()
        case "Driver": return createDriver()
        case "Date": return createDate()
        case "Package": return createPackage()
        case "Values": return createValues()
        default: return nil
        }
    }
}
