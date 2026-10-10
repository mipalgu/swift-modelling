//
//  Type.swift
//

import ECore
import EMFBase
import Foundation

/// A kind of thing.
///
/// The name of this class is a word that Swift reserves.
// @generated
public protocol `Type`: EObject, AnyObject {
    /// The name attribute.
    // @generated
    var name: String? { get set }

    /// The default attribute.
    // @generated
    var `default`: String? { get set }
}
