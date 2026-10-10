//
//  Book.swift
//
//  Copyright 2026 Example Pty Ltd
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Book class.
///
/// Part of the library package.
// @generated
public final class Book: EObject, Named, Lendable {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { LibraryPackage.shared.eBook }

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
        var loanDays: Int = 14
        var onLoan: Bool = false
        var pages: Int = 100
        var category: BookCategory = .Mystery
        var isbn: ISBN? = nil
        var author = EWeakReference(nil)
        var library = EWeakReference(nil)
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

    /// The loanDays attribute.
    // @generated
    public var loanDays: Int {
        get { eStorage.withLock { $0.loanDays } }
        set { eStorage.withLock { $0.loanDays = newValue } }
    }

    /// The onLoan attribute.
    // @generated
    public var onLoan: Bool {
        get { eStorage.withLock { $0.onLoan } }
        set { eStorage.withLock { $0.onLoan = newValue } }
    }

    /// The pages attribute.
    // @generated
    public var pages: Int {
        get { eStorage.withLock { $0.pages } }
        set { eStorage.withLock { $0.pages = newValue } }
    }

    /// The category attribute.
    // @generated
    public var category: BookCategory {
        get { eStorage.withLock { $0.category } }
        set { eStorage.withLock { $0.category = newValue } }
    }

    /// The isbn attribute.
    // @generated
    public var isbn: ISBN? {
        get { eStorage.withLock { $0.isbn } }
        set { eStorage.withLock { $0.isbn = newValue } }
    }

    /// The author reference.
    // @generated
    public var author: Writer? {
        get { eStorage.withLock { $0.author.object as? Writer } }
        set {
            let previous = eStorage.withLock { values -> Writer? in
                let old = values.author.object as? Writer
                values.author = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            previous?.books.removeAll { $0 === self }
            if let newValue, !newValue.books.contains(where: { $0 === self }) { newValue.books.append(self) }
        }
    }

    /// The library reference.
    // @generated
    public var library: Library? {
        get { eStorage.withLock { $0.library.object as? Library } }
        set {
            let previous = eStorage.withLock { values -> Library? in
                let old = values.library.object as? Library
                values.library = EWeakReference(newValue)
                return old
            }
            guard previous !== newValue else { return }
            previous?.books.removeAll { $0 === self }
            if let newValue, !newValue.books.contains(where: { $0 === self }) { newValue.books.append(self) }
        }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Book, rhs: Book) -> Bool { lhs.id == rhs.id }

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
        case "loanDays": return self.loanDays
        case "onLoan": return self.onLoan
        case "pages": return self.pages
        case "category": return self.category
        case "isbn": return self.isbn
        case "author": return self.author
        case "library": return self.library
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
        case "loanDays": self.loanDays = (value as? Int) ?? 14
        case "onLoan": self.onLoan = (value as? Bool) ?? false
        case "pages": self.pages = (value as? Int) ?? 100
        case "category": self.category = (value as? BookCategory) ?? .Mystery
        case "isbn": self.isbn = value as? ISBN
        case "author": self.author = value as? Writer
        case "library": self.library = value as? Library
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
        case "loanDays": return self.loanDays != 14
        case "onLoan": return self.onLoan != false
        case "pages": return self.pages != 100
        case "category": return self.category != .Mystery
        case "isbn": return self.isbn != nil
        case "author": return self.author != nil
        case "library": return self.library != nil
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
