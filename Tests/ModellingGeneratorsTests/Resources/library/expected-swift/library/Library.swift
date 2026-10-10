//
//  Library.swift
//
//  Copyright 2026 Example Pty Ltd
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Library class.
///
/// Part of the library package.
// @generated
public final class Library: EObject, Named {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { LibraryPackage.shared.eLibrary }

    /// The values of the features of the object.
    // @generated
    private struct EStorage: Sendable {
        var name: String? = nil
        var books: [Book] = []
        var writers: [Writer] = []
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

    /// The books reference.
    // @generated
    public var books: [Book] {
        get { eStorage.withLock { $0.books } }
        set { eStorage.withLock { $0.books = newValue } }
    }

    /// The writers reference.
    // @generated
    public var writers: [Writer] {
        get { eStorage.withLock { $0.writers } }
        set { eStorage.withLock { $0.writers = newValue } }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Library, rhs: Library) -> Bool { lhs.id == rhs.id }

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
        case "books": return EcoreValueArray(self.books.map { $0 as any EcoreValue })
        case "writers": return EcoreValueArray(self.writers.map { $0 as any EcoreValue })
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
        case "books": self.books = (value as? EcoreValueArray)?.values.compactMap { $0 as? Book } ?? []
        case "writers": self.writers = (value as? EcoreValueArray)?.values.compactMap { $0 as? Writer } ?? []
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
        case "books": return !self.books.isEmpty
        case "writers": return !self.writers.isEmpty
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
