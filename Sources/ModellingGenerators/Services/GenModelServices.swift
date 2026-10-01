//
// GenModelServices.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation
import GenModel

/// Offers the language-neutral facade of a generator model to templates as AQL services.
///
/// The services wrap `GenElement`: navigation between generator elements, feature and
/// classifier numbering, inherited feature lists, shortcuts to the properties of the Ecore
/// elements that generator elements describe, name formatting and generator settings that fall
/// back to the defaults of the generator metamodel. Receivers are the objects of the
/// generator model; results that are elements are returned as the same kind of object, so
/// templates can keep navigating them with the structural features of the generator metamodel.
///
/// The provider has no knowledge of any target language. Names of the services are listed in
/// ``GenModelServiceName``.
///
/// ## Example
///
/// ```swift
/// let context = await GenModelContext.snapshot(of: resourceSet)
/// let generator = MTLGenerator(
///     module: module, generationStrategy: strategy,
///     serviceProviders: [GenModelServices(context: context)])
/// ```
public struct GenModelServices: AQLServiceProvider {
    /// The snapshot of the generator model that the services read.
    public let context: GenModelContext

    /// The generator classifier for each Ecore classifier, by the identifier of the Ecore classifier.
    let classifiers: [EUUID: GenElement]

    /// Creates the services for a snapshot of a generator model.
    ///
    /// - Parameter context: The snapshot that the services read; it is not updated later.
    public init(context: GenModelContext) {
        self.context = context
        var classifiers: [EUUID: GenElement] = [:]
        for element in context.elements(ofKind: GenModelConstants.ClassName.genClassifier) {
            let identifier = element.ecoreClass?.id ?? element.ecoreEnum?.id ?? element.ecoreDataType?.id
            if let identifier, classifiers[identifier] == nil { classifiers[identifier] = element }
        }
        self.classifiers = classifiers
    }

    /// The services offered to templates.
    public var services: [AQLService] {
        namingServices + navigationServices + classServices + featureServices
            + settingServices + textServices + serialisationServices
    }

    // MARK: - Receivers

    /// The receiver requirement that accepts the objects of the generator model.
    var genElementReceiver: AQLReceiver {
        let context = self.context
        return .custom { value in
            guard let object = value as? DynamicEObject else { return false }
            return context.element(id: object.id) != nil
        }
    }

    /// The receiver requirement that accepts generator elements of one metaclass.
    ///
    /// - Parameter metaclassName: The name of a generator metaclass.
    func genElementReceiver(of metaclassName: String) -> AQLReceiver {
        let context = self.context
        return .custom { value in
            guard let object = value as? DynamicEObject,
                let element = context.element(id: object.id)
            else { return false }
            return element.isKind(of: metaclassName)
        }
    }

    // MARK: - Conversions

    /// The generator element that a call's receiver is.
    ///
    /// - Parameter call: The service call.
    /// - Returns: The element.
    /// - Throws: ``AQLExecutionError/typeError(_:)`` if the receiver is not a generator element.
    func element(of call: AQLServiceCall) throws -> GenElement {
        try element(call.receiver, in: call.name)
    }

    /// The generator element that a value denotes.
    ///
    /// - Parameters:
    ///   - value: The receiver or argument.
    ///   - name: The service name for error messages.
    /// - Returns: The element.
    /// - Throws: ``AQLExecutionError/typeError(_:)`` if the value is not a generator element.
    func element(_ value: (any EcoreValue)?, in name: String) throws -> GenElement {
        guard let object = value as? DynamicEObject, let element = context.element(id: object.id) else {
            throw AQLExecutionError.typeError("\(name) requires a generator model element")
        }
        return element
    }

    /// Wraps elements as a collection value.
    func collection(_ elements: [GenElement]) -> EcoreValueArray {
        AQLValues.collection(elements.map(\.object))
    }

    /// Wraps an optional element as a value.
    func value(_ element: GenElement?) -> (any EcoreValue)? {
        element?.object
    }

    /// The Ecore element described by a generator element, for any kind of generator element.
    func ecoreElement(of element: GenElement) -> (any EcoreValue)? {
        element.ecoreClass ?? element.ecoreFeature.flatMap { $0 as? any EcoreValue }
            ?? element.ecoreEnum ?? element.ecoreEnumLiteral ?? element.ecoreDataType
            ?? element.ecorePackage
    }

    // MARK: - Service construction

    /// Creates a service without parameters on generator elements.
    func property(
        _ name: String, on receiver: AQLReceiver? = nil,
        _ body: @escaping @MainActor @Sendable (GenElement) -> (any EcoreValue)?
    ) -> AQLService {
        let provider = self
        return AQLService(name, receiver: receiver ?? genElementReceiver) { call in
            body(try provider.element(of: call))
        }
    }

    /// Creates a service without parameters that yields generator elements.
    func list(
        _ name: String, on receiver: AQLReceiver? = nil,
        _ body: @escaping @MainActor @Sendable (GenElement) -> [GenElement]
    ) -> AQLService {
        let provider = self
        return AQLService(name, receiver: receiver ?? genElementReceiver) { call in
            provider.collection(body(try provider.element(of: call)))
        }
    }

    /// Creates a service without parameters that yields one generator element or null.
    func link(
        _ name: String, on receiver: AQLReceiver? = nil,
        _ body: @escaping @MainActor @Sendable (GenElement) -> GenElement?
    ) -> AQLService {
        let provider = self
        return AQLService(name, receiver: receiver ?? genElementReceiver) { call in
            provider.value(body(try provider.element(of: call)))
        }
    }
}
