//
// ModelComparer.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import ModellingGenerators

/// Finds the differences between two models.
///
/// Objects are matched by the name of their class and an identity: first by the value of the
/// identifying attribute of their class, then by the value that names them (see
/// ``ObjectNaming``), and finally by their location in the containment tree; a weaker identity
/// matches two objects only if they do not both have a stronger one. Objects with the same class
/// and identity are matched in document order. Matched objects are compared feature
/// by feature; contained objects are compared as objects in their own right, so containment
/// references are not compared as values.
struct ModelComparer: Sendable {
    /// The objects of the original model.
    let original: ModelCatalogue

    /// The objects of the revised model.
    let revised: ModelCatalogue

    /// The features to leave out.
    let filter: ComparisonFilter

    /// The separator between the class name and the identity of an object in a matching key.
    private static let keySeparator = "\u{1F}"

    /// The prefix that keeps the key of a referenced object apart from an attribute value.
    private static let referenceKeyPrefix = "\u{1E}"

    /// What a comparison of two models found.
    struct Outcome: Sendable {
        /// The differences in document order.
        var differences: [Difference]

        /// The numbers of added, removed, changed and unchanged objects.
        var objects: ObjectChanges

        /// The number of objects of the original model that have a counterpart in the revised one.
        var matched: Int
    }

    /// Compares the two models.
    ///
    /// On an interactive terminal, a progress bar shows how many matched objects have been compared.
    ///
    /// - Returns: The differences and the numbers of objects.
    func compare() async -> Outcome {
        let counterparts = match()
        var revisedMatched = Set<Int>()
        let progress = GenerationProgressBar(verbose: false)
        var differences: [Difference] = []
        var changedObjects = 0
        var removed = 0
        for (index, entry) in original.entries.enumerated() {
            progress.show(
                GenerationProgressUpdate(
                    message: ComparisonVocabulary.progressMessage, completed: index, total: original.entries.count))
            guard let counterpart = counterparts[index] else {
                removed += 1
                differences.append(
                    Difference(
                        change: .removed, element: .object, path: original.label(of: entry.object), location: entry.location))
                continue
            }
            revisedMatched.insert(counterpart)
            let changes = await compare(entry, revised.entries[counterpart])
            if !changes.isEmpty { changedObjects += 1 }
            differences += changes
        }
        progress.finish()
        var added = 0
        for (index, entry) in revised.entries.enumerated() where !revisedMatched.contains(index) {
            added += 1
            differences.append(
                Difference(change: .added, element: .object, path: revised.label(of: entry.object), location: entry.location))
        }
        let matched = revisedMatched.count
        return Outcome(
            differences: differences,
            objects: ObjectChanges(added: added, removed: removed, changed: changedObjects, unchanged: matched - changedObjects),
            matched: matched)
    }

    /// The numbers of objects of each class in both models, in alphabetical order of the class names.
    ///
    /// - Returns: The counts of every class that has objects in either model.
    func classCounts() -> [CountComparison] {
        let originalCounts = Dictionary(uniqueKeysWithValues: original.classCounts.map { ($0.name, $0.count) })
        let revisedCounts = Dictionary(uniqueKeysWithValues: revised.classCounts.map { ($0.name, $0.count) })
        return Set(originalCounts.keys).union(revisedCounts.keys).sorted().map { name in
            CountComparison(name: name, original: originalCounts[name] ?? 0, revised: revisedCounts[name] ?? 0)
        }
    }

    // MARK: - Matching

    /// Finds the counterpart of every object of the original model.
    ///
    /// Two objects are matched by a weaker identity only if they do not both have a stronger
    /// one: two objects with different identifiers are never matched by their names or locations.
    ///
    /// - Returns: For each entry of the original model, the index of its counterpart among the
    ///   entries of the revised model, or `nil` if it has none.
    func match() -> [Int?] {
        let identities: [(ModelCatalogue, ModelCatalogue.Entry) -> String?] = [
            Self.identifier(in:of:), Self.name(in:of:), { _, entry in entry.location },
        ]
        let originalKeys = identities.map { identity in original.entries.map { Self.key(of: $0, in: original, identity: identity) } }
        let revisedKeys = identities.map { identity in revised.entries.map { Self.key(of: $0, in: revised, identity: identity) } }
        var counterparts = [Int?](repeating: nil, count: original.entries.count)
        var revisedMatched = [Bool](repeating: false, count: revised.entries.count)
        for pass in identities.indices {
            var candidates: [String: [Int]] = [:]
            for index in original.entries.indices where counterparts[index] == nil {
                guard let key = originalKeys[pass][index] else { continue }
                candidates[key, default: []].append(index)
            }
            for index in revised.entries.indices where !revisedMatched[index] {
                guard let key = revisedKeys[pass][index], let queue = candidates[key],
                    let position = queue.firstIndex(where: { candidate in
                        (0..<pass).allSatisfy { originalKeys[$0][candidate] == nil || revisedKeys[$0][index] == nil }
                    })
                else { continue }
                candidates[key]?.remove(at: position)
                counterparts[queue[position]] = index
                revisedMatched[index] = true
            }
        }
        return counterparts
    }

    /// The key that matches an object: the name of its class and its identity.
    private static func key(
        of entry: ModelCatalogue.Entry, in catalogue: ModelCatalogue,
        identity: (ModelCatalogue, ModelCatalogue.Entry) -> String?
    ) -> String? {
        guard let value = identity(catalogue, entry) else { return nil }
        return catalogue.eClass(of: entry.object).name + keySeparator + value
    }

    /// The value of the identifying attribute of an object, if its class has one and it is set.
    private static func identifier(in catalogue: ModelCatalogue, of entry: ModelCatalogue.Entry) -> String? {
        let object = entry.object
        guard let attribute = MetamodelCatalogue.attributes(of: catalogue.eClass(of: object)).first(where: \.isID),
            object.eIsSet(attribute.name), let value = object.eGet(attribute.name), ValueElements.isScalar(value)
        else { return nil }
        return ValueText.plain(value)
    }

    /// The value that names an object, if it has one.
    private static func name(in catalogue: ModelCatalogue, of entry: ModelCatalogue.Entry) -> String? {
        ObjectNaming.name(of: entry.object, eClass: catalogue.eClass(of: entry.object))
    }

    // MARK: - Values

    /// The differences between the values of two matched objects.
    private func compare(_ originalEntry: ModelCatalogue.Entry, _ revisedEntry: ModelCatalogue.Entry) async -> [Difference] {
        let originalObject = originalEntry.object
        let revisedObject = revisedEntry.object
        let originalClass = original.eClass(of: originalObject)
        let classNames = [originalClass.name] + originalClass.eAllSuperTypes.map(\.name)
        let originalSlots = ObjectFeatures.slots(of: originalObject, eClass: originalClass)
        let revisedSlots = ObjectFeatures.slots(of: revisedObject, eClass: revised.eClass(of: revisedObject))
        var names = originalSlots.map(\.name)
        for slot in revisedSlots where !names.contains(slot.name) { names.append(slot.name) }
        var differences: [Difference] = []
        for name in names where !filter.ignoresFeature(name, ofClassesNamed: classNames) {
            let originalSlot = originalSlots.first { $0.name == name }
            let revisedSlot = revisedSlots.first { $0.name == name }
            let roles = [originalSlot?.role, revisedSlot?.role].compactMap { $0 }
            guard !roles.contains(.containment), !roles.contains(.container) else { continue }
            let before = await value(of: originalSlot, alternative: revisedSlot, object: originalObject, in: original)
            let after = await value(of: revisedSlot, alternative: originalSlot, object: revisedObject, in: revised)
            guard before.key != after.key else { continue }
            differences.append(
                Difference(
                    change: .changed, element: .object, path: original.label(of: originalObject),
                    location: originalEntry.location, property: name, original: before.text, revised: after.text))
        }
        return differences
    }

    /// The value of a feature of an object, as a key to compare and a text to show.
    ///
    /// - Parameters:
    ///   - slot: The feature, if the object sets it.
    ///   - alternative: The same feature of the other object, which tells how an unset feature reads.
    ///   - object: The object.
    ///   - catalogue: The objects of the model of the object.
    /// - Returns: The key and the text of the value.
    private func value(
        of slot: FeatureSlot?, alternative: FeatureSlot?, object: DynamicEObject, in catalogue: ModelCatalogue
    ) async -> (key: [String], text: String) {
        guard let slot else {
            let isMany = alternative?.isMany ?? false
            if let name = alternative?.name, !isMany, catalogue.eClass(of: object).eAllAttributes.contains(where: { $0.name == name }),
                let value = object.eGetWithDefault(name)
            {
                return (ValueElements.of(value).map(ValueText.plain), ValueText.describe(value))
            }
            return ([], isMany ? ComparisonVocabulary.emptyList : ComparisonVocabulary.unsetValue)
        }
        switch slot.role {
        case .attribute:
            let text = slot.attribute.map { ValueText.describe(slot.value, of: $0) } ?? ValueText.describe(slot.value)
            return (ValueElements.of(slot.value).map(ValueText.plain), text)
        case .containment, .container, .crossReference:
            var targets: [String] = []
            for element in ValueElements.of(slot.value) {
                targets.append(await target(element, in: catalogue))
            }
            let text = slot.isMany ? "[" + targets.joined(separator: ComparisonVocabulary.listSeparator) + "]" : targets.first ?? ""
            return (targets.map { Self.referenceKeyPrefix + $0 }, text)
        }
    }

    /// Describes a referenced object by its label, adding its location if nothing names it.
    ///
    /// A reference into another document is described with that document, and a reference
    /// that leads to no object as ``ComparisonVocabulary/unresolvedTarget``.
    private func target(_ element: any EcoreValue, in catalogue: ModelCatalogue) async -> String {
        guard let id = ObjectFeatures.identifier(of: element), let entry = catalogue.entry(for: id) else {
            if let id = element as? EUUID, !(await catalogue.resourceSet.resolve(id)?.object is DynamicEObject) {
                return ComparisonVocabulary.unresolvedTarget
            }
            return await catalogue.describeTargets(of: element).first ?? ValueText.describe(element)
        }
        let object = entry.object
        guard ObjectNaming.name(of: object, eClass: catalogue.eClass(of: object)) != nil else {
            return catalogue.labelWithLocation(of: object)
        }
        return catalogue.label(of: object)
    }
}
