//
// GenModelServices+Serialisation.swift
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
    /// Services that write the Ecore model of a generator package as text.
    var serialisationServices: [AQLService] {
        typealias Name = GenModelServiceName
        let provider = self
        return [
            AQLService(
                Name.serialisedEcore, receiver: genElementReceiver(of: GenModelConstants.ClassName.genPackage),
                arity: 0...1
            ) { call in
                let element = try provider.element(of: call)
                guard let package = element.ecorePackage else { return nil }
                let omitted = call.arguments.isEmpty ? nil : call.argument(0) as? String
                let kept = omitted.map { Self.removingAnnotations(ofSource: $0, from: package) } ?? package
                return XMISerializer().serialize(kept)
            }
        ]
    }

    /// A copy of a package without the annotations of one source.
    ///
    /// The annotations are removed from the package, its classifiers, their features, operations,
    /// parameters and literals, and from nested packages.
    ///
    /// - Parameters:
    ///   - source: The source of the annotations to leave out.
    ///   - package: The package to copy.
    /// - Returns: The package without those annotations.
    static func removingAnnotations(ofSource source: String, from package: EPackage) -> EPackage {
        func kept(_ annotations: [EAnnotation]) -> [EAnnotation] { annotations.filter { $0.source != source } }
        var result = package
        result.eAnnotations = kept(result.eAnnotations)
        result.eClassifiers = result.eClassifiers.map { classifier in
            switch classifier {
            case var eClass as EClass:
                eClass.eAnnotations = kept(eClass.eAnnotations)
                eClass.eStructuralFeatures = eClass.eStructuralFeatures.map { feature in
                    switch feature {
                    case var attribute as EAttribute:
                        attribute.eAnnotations = kept(attribute.eAnnotations)
                        return attribute
                    case var reference as EReference:
                        reference.eAnnotations = kept(reference.eAnnotations)
                        return reference
                    default: return feature
                    }
                }
                eClass.eOperations = eClass.eOperations.map { operation in
                    var operation = operation
                    operation.eAnnotations = kept(operation.eAnnotations)
                    operation.eParameters = operation.eParameters.map { parameter in
                        var parameter = parameter
                        parameter.eAnnotations = kept(parameter.eAnnotations)
                        return parameter
                    }
                    return operation
                }
                return eClass
            case var eEnum as EEnum:
                eEnum.eAnnotations = kept(eEnum.eAnnotations)
                eEnum.literals = eEnum.literals.map { literal in
                    var literal = literal
                    literal.eAnnotations = kept(literal.eAnnotations)
                    return literal
                }
                return eEnum
            case var dataType as EDataType:
                dataType.eAnnotations = kept(dataType.eAnnotations)
                return dataType
            default: return classifier
            }
        }
        result.eSubpackages = result.eSubpackages.map { removingAnnotations(ofSource: source, from: $0) }
        return result
    }
}
