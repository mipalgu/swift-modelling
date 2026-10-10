//
//  Values.swift
//

import ECore
import EMFBase
import Foundation
import Synchronization

/// The Values class.
///
/// Part of the swiftnames package.
// @generated
public final class Values: EObject {
    /// The type of the metaclass of the object.
    // @generated
    public typealias Classifier = EClass

    /// The unique identifier of the object.
    // @generated
    public let id: EUUID

    /// The metaclass that describes the object.
    // @generated
    public var eClass: EClass { SwiftnamesPackage.shared.eValues }

    /// The values of the features of the object.
    // @generated
    private struct EStorage: Sendable {
        var big: EBigInteger? = nil
        var money: Decimal? = nil
        var bytes: [Int8]? = nil
        var initial: Character = "x"
        var payload: (any EcoreValue)? = nil
        var ratio: Float = 0.5
        var small: Int16 = 0
        var tiny: Int8 = 0
        var huge: Int64 = 99999999999
        var flag: Bool? = nil
        var count: Int? = 7
        var stamp: Stamp? = nil
        var mood: Mood? = nil
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

    /// The big attribute.
    // @generated
    public var big: EBigInteger? {
        get { eStorage.withLock { $0.big } }
        set { eStorage.withLock { $0.big = newValue } }
    }

    /// The money attribute.
    // @generated
    public var money: Decimal? {
        get { eStorage.withLock { $0.money } }
        set { eStorage.withLock { $0.money = newValue } }
    }

    /// The bytes attribute.
    // @generated
    public var bytes: [Int8]? {
        get { eStorage.withLock { $0.bytes } }
        set { eStorage.withLock { $0.bytes = newValue } }
    }

    /// The initial attribute.
    // @generated
    public var initial: Character {
        get { eStorage.withLock { $0.initial } }
        set { eStorage.withLock { $0.initial = newValue } }
    }

    /// The payload attribute.
    // @generated
    public var payload: (any EcoreValue)? {
        get { eStorage.withLock { $0.payload } }
        set { eStorage.withLock { $0.payload = newValue } }
    }

    /// The ratio attribute.
    // @generated
    public var ratio: Float {
        get { eStorage.withLock { $0.ratio } }
        set { eStorage.withLock { $0.ratio = newValue } }
    }

    /// The small attribute.
    // @generated
    public var small: Int16 {
        get { eStorage.withLock { $0.small } }
        set { eStorage.withLock { $0.small = newValue } }
    }

    /// The tiny attribute.
    // @generated
    public var tiny: Int8 {
        get { eStorage.withLock { $0.tiny } }
        set { eStorage.withLock { $0.tiny = newValue } }
    }

    /// The huge attribute.
    // @generated
    public var huge: Int64 {
        get { eStorage.withLock { $0.huge } }
        set { eStorage.withLock { $0.huge = newValue } }
    }

    /// The flag attribute.
    // @generated
    public var flag: Bool? {
        get { eStorage.withLock { $0.flag } }
        set { eStorage.withLock { $0.flag = newValue } }
    }

    /// The count attribute.
    // @generated
    public var count: Int? {
        get { eStorage.withLock { $0.count } }
        set { eStorage.withLock { $0.count = newValue } }
    }

    /// The stamp attribute.
    // @generated
    public var stamp: Stamp? {
        get { eStorage.withLock { $0.stamp } }
        set { eStorage.withLock { $0.stamp = newValue } }
    }

    /// The mood attribute.
    // @generated
    public var mood: Mood? {
        get { eStorage.withLock { $0.mood } }
        set { eStorage.withLock { $0.mood = newValue } }
    }

    /// Compares two objects by their identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The first object to compare.
    ///   - rhs: The second object to compare.
    /// - Returns: `true` if the identifiers match.
    // @generated
    public static func == (lhs: Values, rhs: Values) -> Bool { lhs.id == rhs.id }

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
        case "big": return self.big
        case "money": return self.money
        case "bytes": return self.bytes
        case "initial": return self.initial
        case "payload": return self.payload
        case "ratio": return self.ratio
        case "small": return self.small
        case "tiny": return self.tiny
        case "huge": return self.huge
        case "flag": return self.flag
        case "count": return self.count
        case "stamp": return self.stamp
        case "mood": return self.mood
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
        case "big": self.big = value as? EBigInteger
        case "money": self.money = value as? Decimal
        case "bytes": self.bytes = value as? [Int8]
        case "initial": self.initial = (value as? Character) ?? "x"
        case "payload": self.payload = value
        case "ratio": self.ratio = (value as? Float) ?? 0.5
        case "small": self.small = (value as? Int16) ?? 0
        case "tiny": self.tiny = (value as? Int8) ?? 0
        case "huge": self.huge = (value as? Int64) ?? 99999999999
        case "flag": self.flag = value as? Bool
        case "count": self.count = (value as? Int) ?? 7
        case "stamp": self.stamp = value as? Stamp
        case "mood": self.mood = value as? Mood
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
        case "big": return self.big != nil
        case "money": return self.money != nil
        case "bytes": return self.bytes != nil
        case "initial": return self.initial != "x"
        case "payload": return self.payload != nil
        case "ratio": return self.ratio != 0.5
        case "small": return self.small != 0
        case "tiny": return self.tiny != 0
        case "huge": return self.huge != 99999999999
        case "flag": return self.flag != nil
        case "count": return self.count != 7
        case "stamp": return self.stamp != nil
        case "mood": return self.mood != nil
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
