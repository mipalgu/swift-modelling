//
// GenModelReconciler.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import GenModel

/// Keeps the settings of an existing generator model while re-synchronising its structure.
///
/// A freshly imported generator model describes the current source models with default
/// settings. Reconciling copies the settings of an existing generator model onto it: the
/// settings of the generator model itself, and the settings of every generator package,
/// classifier, feature, operation, parameter and literal that has a counterpart of the same
/// name in the existing model. Elements that are new in the sources keep their defaults, and
/// elements that no longer exist in the sources are dropped because the fresh model never
/// contains them.
///
/// The settings that describe where the sources are (`foreignModel` and `importerID`) always
/// come from the fresh import. Settings that the caller gave explicitly take precedence over
/// the existing model.
enum GenModelReconciler {
    /// Copies the settings of an existing generator model onto a freshly imported one.
    ///
    /// - Parameters:
    ///   - resource: The resource holding the fresh generator model.
    ///   - resourceSet: The resource set holding the resource and the source models.
    ///   - reload: The location of the existing generator model.
    ///   - options: The import options, whose explicit settings take precedence.
    /// - Throws: ``GenerationError/reloadModelUnreadable(_:_:)`` if the existing model is missing or
    ///   cannot be read.
    static func reconcile(
        _ resource: Resource, in resourceSet: ResourceSet, with reload: URL,
        overriding options: GenModelImportOptions
    ) async throws {
        guard FileManager.default.fileExists(atPath: reload.path) else {
            throw GenerationError.reloadModelUnreadable(reload.path, "the file does not exist")
        }
        let existingSet = ResourceSet()
        do {
            _ = try await GenModelResource.loadDocument(
                url: reload, resourceSet: existingSet, resolution: .nameFragments)
        } catch {
            throw GenerationError.reloadModelUnreadable(reload.path, String(describing: error))
        }
        let existing = await GenModelContext.snapshot(of: existingSet)
        var packages: [EPackage] = []
        for uri in await resourceSet.getMetamodelURIs().sorted() {
            if let package = await resourceSet.getMetamodel(uri: uri) { packages.append(package) }
        }
        let fresh = await GenModelContext.snapshot(of: [resource], ecorePackages: packages)
        guard let oldModel = existing.genModels.first else {
            throw GenerationError.reloadModelUnreadable(reload.path, "it contains no generator model")
        }
        guard let newModel = fresh.genModels.first else { return }

        var reconciler = Reconciliation(resource: resource, options: options)
        await reconciler.reconcileModel(newModel, with: oldModel)
    }

    /// The state of one reconciliation.
    private struct Reconciliation {
        let resource: Resource
        let options: GenModelImportOptions

        /// Reconciles the generator model and everything below it.
        mutating func reconcileModel(_ new: GenElement, with old: GenElement) async {
            await copySettings(from: old, to: new, skipping: skippedModelSettings)
            await copyUsedGenPackages(from: old, to: new)
            for package in new.genPackages {
                if let counterpart = old.genPackages.first(where: { Self.samePackage($0, package) }) {
                    await reconcilePackage(package, with: counterpart)
                }
            }
        }

        private var skippedModelSettings: Set<String> {
            typealias Name = GenModelImportConstants.Setting
            var skipped = Name.derivedFromSources
            if options.complianceLevel != nil { skipped.insert(Name.complianceLevel) }
            if options.copyright != nil { skipped.insert(Name.copyrightText) }
            if options.modelPluginID != nil { skipped.insert(Name.modelPluginID) }
            if options.modelDirectory != nil { skipped.insert(Name.modelDirectory) }
            return skipped
        }

        private func skippedPackageSettings(of package: GenElement) -> Set<String> {
            typealias Name = GenModelImportConstants.Setting
            var skipped: Set<String> = []
            let isRoot = package.parentGenPackage == nil
            if isRoot && options.basePackage != nil { skipped.insert(Name.basePackage) }
            if (isRoot && options.prefix != nil) || options.packagePrefixes[package.name] != nil {
                skipped.insert(Name.prefix)
            }
            return skipped
        }

        /// Whether two generator packages describe the same Ecore package.
        private static func samePackage(_ lhs: GenElement, _ rhs: GenElement) -> Bool {
            guard let left = lhs.ecorePackage, let right = rhs.ecorePackage else { return false }
            if left.nsURI.isEmpty || right.nsURI.isEmpty { return left.name == right.name }
            return left.nsURI == right.nsURI
        }

        mutating func reconcilePackage(_ new: GenElement, with old: GenElement) async {
            await copySettings(from: old, to: new, skipping: skippedPackageSettings(of: new))
            await reconcileChildren(new.genClasses, old.genClasses, kind: .genClass)
            await reconcileChildren(new.genEnums, old.genEnums, kind: .genEnum)
            await reconcileChildren(new.genDataTypes, old.genDataTypes, kind: .simple)
            for package in new.nestedGenPackages {
                if let counterpart = old.nestedGenPackages.first(where: { Self.samePackage($0, package) }) {
                    await reconcilePackage(package, with: counterpart)
                }
            }
        }

        mutating func reconcileClass(_ new: GenElement, with old: GenElement) async {
            await copySettings(from: old, to: new)
            await reconcileChildren(new.genFeatures, old.genFeatures, kind: .simple)
            for operation in new.genOperations {
                if let counterpart = old.genOperations.first(where: { Self.sameOperation($0, operation) }) {
                    await reconcileOperation(operation, with: counterpart)
                }
            }
            for (fresh, existing) in zip(new.genTypeParameters, old.genTypeParameters) {
                await copySettings(from: existing, to: fresh)
            }
            await copyLabelFeature(from: old, to: new)
        }

        mutating func reconcileEnum(_ new: GenElement, with old: GenElement) async {
            await copySettings(from: old, to: new)
            await reconcileChildren(new.genEnumLiterals, old.genEnumLiterals, kind: .simple)
        }

        mutating func reconcileOperation(_ new: GenElement, with old: GenElement) async {
            await copySettings(from: old, to: new)
            for (fresh, existing) in zip(new.genParameters, old.genParameters) {
                await copySettings(from: existing, to: fresh)
            }
            for (fresh, existing) in zip(new.genTypeParameters, old.genTypeParameters) {
                await copySettings(from: existing, to: fresh)
            }
        }

        mutating func reconcileSimple(_ new: GenElement, with old: GenElement) async {
            await copySettings(from: old, to: new)
        }

        /// The kinds of elements that are matched by name.
        private enum Kind {
            case genClass, genEnum, simple
        }

        /// Reconciles elements that are matched by name.
        private mutating func reconcileChildren(
            _ new: [GenElement], _ old: [GenElement], kind: Kind
        ) async {
            for element in new {
                guard let counterpart = old.first(where: { $0.name == element.name }) else { continue }
                switch kind {
                case .genClass: await reconcileClass(element, with: counterpart)
                case .genEnum: await reconcileEnum(element, with: counterpart)
                case .simple: await reconcileSimple(element, with: counterpart)
                }
            }
        }

        private static func sameOperation(_ lhs: GenElement, _ rhs: GenElement) -> Bool {
            lhs.name == rhs.name && lhs.genParameters.count == rhs.genParameters.count
        }

        /// Copies every attribute setting of one generator element onto another.
        ///
        /// A setting that is unset in the existing element is unset in the fresh element too,
        /// unless the setting is unsettable, in which case the fresh value is kept.
        private func copySettings(
            from old: GenElement, to new: GenElement, skipping skipped: Set<String> = []
        ) async {
            guard let eClass = new.object.eClass as? EClass else { return }
            for attribute in eClass.allAttributes
            where !attribute.derived && !attribute.volatile && !attribute.transient
                && !skipped.contains(attribute.name)
            {
                if let value = old.object.eGet(attribute.name) {
                    _ = await resource.eSet(
                        objectId: new.object.id, feature: attribute.name,
                        value: Self.typed(value, for: attribute))
                } else if !attribute.unsettable {
                    _ = await resource.eSet(
                        objectId: new.object.id, feature: attribute.name, value: nil)
                }
            }
        }

        /// Converts the text of a setting to the type of its attribute.
        private static func typed(_ value: any EcoreValue, for attribute: EAttribute) -> any EcoreValue {
            if let array = value as? EcoreValueArray {
                let texts = array.values.compactMap { $0 as? String }
                return texts.count == array.values.count ? texts : value
            }
            guard let text = value as? String else { return value }
            switch EcoreDataType(rawValue: attribute.eType.name) {
            case .eBoolean: return text == "true"
            case .eInt: return Int(text) ?? text
            default: return text
            }
        }

        /// Keeps the generator packages that the existing model uses.
        private func copyUsedGenPackages(from old: GenElement, to new: GenElement) async {
            let feature = GenModelConstants.FeatureName.usedGenPackages
            var proxies: [ResourceProxy] = []
            switch old.object.eGet(feature) {
            case let list as [ResourceProxy]: proxies = list
            case let proxy as ResourceProxy: proxies = [proxy]
            case let texts as [String]: proxies = texts.compactMap(Self.proxy(from:))
            case let text as String: proxies = Self.proxy(from: text).map { [$0] } ?? []
            default: break
            }
            guard !proxies.isEmpty else { return }
            _ = await resource.eSet(objectId: new.object.id, feature: feature, value: proxies)
        }

        private static func proxy(from text: String) -> ResourceProxy? {
            guard let separator = text.firstIndex(of: GenModelConstants.fragmentSeparator) else { return nil }
            return ResourceProxy(
                uri: String(text[..<separator]),
                fragment: String(text[text.index(after: separator)...]))
        }

        /// Re-selects the label feature of a class by the name of the feature in the existing model.
        private func copyLabelFeature(from old: GenElement, to new: GenElement) async {
            let feature = GenModelConstants.FeatureName.labelFeature
            guard let oldID = GenModelContextAccess.identifier(of: old.object, feature: feature),
                let oldLabel = old.context.element(id: oldID),
                let counterpart = new.genFeatures.first(where: { $0.name == oldLabel.name })
            else { return }
            _ = await resource.eSet(objectId: new.object.id, feature: feature, value: counterpart.object.id)
        }
    }
}

/// Reads reference identifiers from generator model objects.
private enum GenModelContextAccess {
    /// The identifier that a single-valued reference points at.
    static func identifier(of object: DynamicEObject, feature: String) -> EUUID? {
        switch object.eGet(feature) {
        case let id as EUUID: return id
        case let target as DynamicEObject: return target.id
        default: return nil
        }
    }
}
