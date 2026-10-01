//
// GenModelServices+Settings.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation
import GenModel

extension GenModelServices {
    /// The names of the Ecore data types whose defaults the settings services understand.
    enum SettingTypeName {
        /// The names of Boolean data types.
        static let booleans: Set<String> = ["EBoolean", "EBooleanObject"]
        /// The names of integral data types.
        static let integers: Set<String> = [
            "EInt", "EIntegerObject", "ELong", "ELongObject", "EShort", "EShortObject", "EByte",
            "EByteObject",
        ]
    }

    /// Services for generator settings, model documentation and annotations.
    var settingServices: [AQLService] {
        typealias Name = GenModelServiceName
        let provider = self
        let nativeElement: AQLReceiver = .custom { $0 is any EModelElement }
        return [
            AQLService(Name.setting, receiver: genElementReceiver, arity: 1) { call in
                Self.setting(try call.string(0), of: try provider.element(of: call))
            },
            AQLService(Name.isSetting, receiver: genElementReceiver, arity: 1) { call in
                try provider.element(of: call).object.eIsSet(try call.string(0))
            },
            AQLService(Name.documentation, receiver: genElementReceiver) { call in
                provider.documentation(of: try provider.element(of: call))
            },
            AQLService(Name.documentation, receiver: nativeElement) { call in
                Self.documentation(of: call.receiver)
            },
            AQLService(Name.hasDocumentation, receiver: genElementReceiver) { call in
                provider.documentation(of: try provider.element(of: call)) != nil
            },
            AQLService(Name.hasDocumentation, receiver: nativeElement) { call in
                Self.documentation(of: call.receiver) != nil
            },
            AQLService(Name.annotationDetail, receiver: genElementReceiver, arity: 2) { call in
                Self.annotationDetail(
                    of: provider.ecoreElement(of: try provider.element(of: call)),
                    source: try call.string(0), key: try call.string(1))
            },
            AQLService(Name.annotationDetail, receiver: nativeElement, arity: 2) { call in
                Self.annotationDetail(of: call.receiver, source: try call.string(0), key: try call.string(1))
            },
        ]
    }

    /// The value of a setting of a generator element.
    ///
    /// The value that the element holds is returned if it is set. Otherwise the default that the
    /// generator metamodel declares for the setting is converted to the type of the setting. A
    /// Boolean setting without default is `false`, an integer setting without default is zero, an
    /// enumeration setting without default is its first literal, and any other setting without a
    /// default is null.
    ///
    /// - Parameters:
    ///   - name: The name of the setting, an attribute of the generator metaclass.
    ///   - element: The generator element.
    /// - Returns: The value of the setting.
    static func setting(_ name: String, of element: GenElement) -> (any EcoreValue)? {
        let attribute = element.object.eClass.getStructuralFeature(name: name) as? EAttribute
        if element.object.eIsSet(name), let value = element.object.eGet(name) {
            if let enumeration = attribute?.eType as? EEnum {
                return element.stringValue(name) ?? literalText(of: value, in: enumeration)
            }
            return value
        }
        guard let attribute else { return element.object.eGet(name) }
        if let enumeration = attribute.eType as? EEnum {
            let literal = attribute.defaultValueLiteral
            let match = enumeration.literals.first { ($0.literal ?? $0.name) == literal || $0.name == literal }
            return (match ?? enumeration.literals.first).map { $0.literal ?? $0.name }
        }
        let typeName = attribute.eType.name
        if SettingTypeName.booleans.contains(typeName) {
            return attribute.defaultValueLiteral.map { $0.lowercased() == "true" } ?? false
        }
        if SettingTypeName.integers.contains(typeName) {
            return attribute.defaultValueLiteral.flatMap { Int($0) } ?? 0
        }
        return attribute.defaultValueLiteral
    }

    /// The text of an enumeration literal that a loaded value stands for.
    ///
    /// A document that lists a literal such as `17.0` can load it as a number, so the value is
    /// matched with the literals of the enumeration numerically as well as textually.
    ///
    /// - Parameters:
    ///   - value: The loaded value.
    ///   - enumeration: The enumeration the value belongs to.
    /// - Returns: The text of the matching literal, or the description of the value if none matches.
    static func literalText(of value: any EcoreValue, in enumeration: EEnum) -> any EcoreValue {
        if value is String { return value }
        if let number = AQLValues.numericValue(value) {
            for literal in enumeration.literals {
                let text = literal.literal ?? literal.name
                if Double(text) == number { return text }
            }
        }
        return AQLValues.description(of: value)
    }

    /// The model documentation of a generator element.
    ///
    /// - Parameter element: The generator element.
    /// - Returns: The documentation of the Ecore element it describes, or `nil` if there is none.
    func documentation(of element: GenElement) -> String? {
        Self.documentation(of: ecoreElement(of: element))
    }

    /// The model documentation of an Ecore element.
    ///
    /// - Parameter value: A model element.
    /// - Returns: The documentation held by the generator model annotation, or `nil` if there is none.
    static func documentation(of value: (any EcoreValue)?) -> String? {
        annotationDetail(
            of: value, source: GenModelConstants.documentationSource,
            key: GenModelConstants.documentationKey)
    }

    /// The value of a detail of an annotation of an Ecore element.
    ///
    /// - Parameters:
    ///   - value: A model element.
    ///   - source: The source of the annotation.
    ///   - key: The key of the detail.
    /// - Returns: The detail value, or `nil` if the element has no such annotation or detail.
    static func annotationDetail(of value: (any EcoreValue)?, source: String, key: String) -> String? {
        guard let element = value as? any EModelElement else { return nil }
        return element.getEAnnotation(source: source)?.details[key]
    }
}
