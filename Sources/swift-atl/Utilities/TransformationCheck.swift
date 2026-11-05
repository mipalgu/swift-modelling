//
// TransformationCheck.swift
// swift-atl
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ECore

/// The checks of a transformation against the metamodels it is bound to.
///
/// The checks find what would make a run fail or produce incomplete models before any model is
/// read: a metamodel without classifiers, a model element type that its metamodel does not
/// define, a binding of a feature that the class of its target element does not have, and a
/// rule that deletes its matched element with `drop` outside refining mode.
/// They cover the source and target patterns of the matched and called rules and the context
/// types of the helpers; expressions are not type-checked.
enum TransformationCheck {
    /// The separator between the metamodel name and the classifier name of a model element
    /// type, as in `Families!Member`.
    static let metamodelSeparator: Character = "!"

    /// The problems of a module, in the order of its declarations.
    ///
    /// - Parameter module: The module, with its metamodels bound.
    /// - Returns: One sentence for each problem; empty if the module passes every check.
    static func problems(of module: ATLModule) -> [String] {
        let metamodels = metamodelsByName(of: module)
        var problems = metamodels.filter { $0.value.eClassifiers.isEmpty }.keys.sorted().map {
            "Metamodel '\($0)' has no classifiers: no metamodel file was found for it"
        }
        let usable = metamodels.filter { !$0.value.eClassifiers.isEmpty }

        /// Checks a model element type and returns its class, if the type names one.
        func check(type: String, in declaration: String) -> EClass? {
            let parts = type.split(separator: metamodelSeparator, maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            guard let package = metamodels[parts[0]] else {
                problems.append("\(declaration) uses '\(type)', but the module declares no metamodel '\(parts[0])'")
                return nil
            }
            guard usable[parts[0]] != nil else { return nil }
            guard let classifier = package.getClassifier(parts[1], includingSubpackages: true) else {
                problems.append("\(declaration) uses '\(type)', which metamodel '\(parts[0])' does not define")
                return nil
            }
            return classifier as? EClass
        }

        /// Checks the types and bound features of target patterns.
        func check(targets: [ATLTargetPattern], in declaration: String) {
            for target in targets {
                guard let eClass = check(type: target.type, in: declaration) else { continue }
                for binding in target.bindings where eClass.getStructuralFeature(name: binding.property) == nil {
                    problems.append(
                        "\(declaration) binds '\(binding.property)', which '\(target.type)' does not have")
                }
            }
        }

        for (name, helper) in module.helpers {
            if let context = helper.contextType {
                _ = check(type: context, in: "Helper '\(name)'")
            }
        }
        for rule in module.matchedRules {
            let declaration = "Rule '\(rule.name)'"
            if rule.dropsSourceElement && !module.isRefining {
                problems.append("\(declaration) deletes its matched element with 'drop', which needs refining mode")
            }
            for source in rule.sourcePatterns {
                _ = check(type: source.type, in: declaration)
            }
            check(targets: rule.targetPatterns, in: declaration)
        }
        for (name, rule) in module.calledRules {
            check(targets: rule.targetPatterns, in: "Rule '\(name)'")
        }
        return problems
    }

    /// The packages of a module by the names that its header gives the metamodels.
    ///
    /// - Parameter module: The module.
    /// - Returns: The package of each metamodel name.
    static func metamodelsByName(of module: ATLModule) -> [String: EPackage] {
        var packages: [String: EPackage] = [:]
        for (alias, package) in Array(module.sourceMetamodels) + Array(module.targetMetamodels) {
            packages[TransformMetamodelOptions.metamodelName(alias: alias, package: package, in: module)] = package
        }
        return packages
    }
}
