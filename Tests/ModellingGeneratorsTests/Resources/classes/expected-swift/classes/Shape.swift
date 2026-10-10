//
//  Shape.swift
//

import ECore
import EMFBase
import Foundation

/// A shape on a canvas.
/// Shapes know their bounds.
/// @since 1.2
// @generated
public protocol Shape: EObject, AnyObject {
    /// The label of the shape.
    // @generated
    var label: String? { get set }

    /// The visible attribute.
    // @generated
    var visible: Bool { get set }

    /// The weight attribute.
    // @generated
    var weight: Double { get set }

    /// The tags attribute.
    // @generated
    var tags: [String] { get set }

    /// The levels attribute.
    // @generated
    var levels: [Int] { get set }

    /// The colour attribute.
    // @generated
    var colour: Colour { get set }

    /// The description attribute.
    // @generated
    var description: String? { get set }

    /// The canvas reference.
    // @generated
    var canvas: Canvas? { get set }
}
