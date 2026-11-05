//
// ObjectFeatures.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// A feature that an object sets, with its value and the part it plays.
struct FeatureSlot: Sendable {
    /// The part that a feature plays for its object.
    enum Role: Sendable, Equatable {
        /// An attribute, or a feature that no class declares and whose value refers to no object.
        case attribute

        /// A reference that contains its targets.
        case containment

        /// A reference to the container of the object.
        case container

        /// A reference to objects that the object does not contain.
        case crossReference
    }

    /// The name of the feature.
    let name: String

    /// The part the feature plays.
    let role: Role

    /// The attribute, if the class of the object declares the feature as one.
    let attribute: EAttribute?

    /// Whether the feature holds a list of values.
    let isMany: Bool

    /// The value that the object sets.
    let value: any EcoreValue
}

/// Lists the features that the objects of a model set.
enum ObjectFeatures {
    /// The features that an object sets, in the order of its class, followed by the features
    /// that its class does not declare.
    ///
    /// A feature that the class does not declare, or declares as an attribute, is a
    /// cross-reference if every element of its value refers to an object, as when the classes of
    /// a model are inferred without a metamodel, and an attribute otherwise.
    ///
    /// - Parameters:
    ///   - object: The object.
    ///   - eClass: The canonical class of the object.
    /// - Returns: One slot for every feature that the object sets.
    static func slots(of object: DynamicEObject, eClass: EClass) -> [FeatureSlot] {
        var slots: [FeatureSlot] = []
        var declared: Set<String> = []
        for feature in eClass.eAllStructuralFeatures {
            declared.insert(feature.name)
            guard object.eIsSet(feature.name), let value = object.eGet(feature.name) else { continue }
            switch feature {
            case let attribute as EAttribute where refersToObjects(value):
                slots.append(FeatureSlot(name: attribute.name, role: .crossReference, attribute: nil, isMany: attribute.isMany, value: value))
            case let attribute as EAttribute:
                slots.append(FeatureSlot(name: attribute.name, role: .attribute, attribute: attribute, isMany: attribute.isMany, value: value))
            case let reference as EReference:
                let role: FeatureSlot.Role = reference.containment ? .containment : reference.container ? .container : .crossReference
                slots.append(FeatureSlot(name: reference.name, role: role, attribute: nil, isMany: reference.isMany, value: value))
            default:
                continue
            }
        }
        for name in object.getFeatureNames() where !declared.contains(name) {
            guard let value = object.eGet(name) else { continue }
            slots.append(
                FeatureSlot(
                    name: name, role: refersToObjects(value) ? .crossReference : .attribute, attribute: nil,
                    isMany: !ValueElements.isScalar(value), value: value))
        }
        return slots
    }

    /// Whether every element of a value refers to an object.
    ///
    /// - Parameter value: The value of a feature.
    /// - Returns: `true` if the value has at least one element and each refers to an object.
    static func refersToObjects(_ value: any EcoreValue) -> Bool {
        let elements = ValueElements.of(value)
        return !elements.isEmpty && elements.allSatisfy(isObjectReference)
    }

    /// Whether an element of a value refers to an object.
    ///
    /// - Parameter element: The element.
    /// - Returns: `true` for an identifier, an object or a reference into another document.
    static func isObjectReference(_ element: any EcoreValue) -> Bool {
        element is EUUID || element is DynamicEObject || element is ResourceProxy
    }

    /// The identifier of the object that an element of a reference value refers to, if it names one.
    ///
    /// - Parameter element: The element.
    /// - Returns: The identifier, or `nil` for a reference into another document or a non-object.
    static func identifier(of element: any EcoreValue) -> EUUID? {
        (element as? EUUID) ?? (element as? DynamicEObject)?.id
    }
}
