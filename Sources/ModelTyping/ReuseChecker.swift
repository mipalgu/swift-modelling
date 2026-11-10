//
//  ReuseChecker.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import AQL
import ATL
import MTL

/// Decides whether ATL, MTL and AQL modules written against one metamodel can be reused with another.
///
/// Each entry point extracts the footprint of the module against the required
/// model types and then runs ``ModelTypeChecker`` in the requested mode. The
/// footprint is extracted in every mode, so that the report always lists the
/// elements the module uses and the gaps in static knowledge.
public enum ReuseChecker {
    /// Checks an ATL module.
    ///
    /// - Parameters:
    ///   - module: The parsed module.
    ///   - required: The model types the module was written against, indexed by the
    ///     metamodel names of its header.
    ///   - provided: The model types to check, indexed by the same names.
    ///   - mode: The subtyping relation to decide (default: ``SubtypingMode/partial``).
    ///   - options: The options of the check (default: standard options).
    /// - Returns: The report.
    public static func check(
        atl module: ATLModule, required: [String: ModelType], provided: [String: ModelType],
        mode: SubtypingMode = .partial, options: CheckOptions = CheckOptions()
    ) -> CompatibilityReport {
        let footprint = ATLFootprintExtractor(metamodels: required).footprint(of: module)
        let relevant = required.filter { footprint.metamodels[$0.key] != nil }
        return ModelTypeChecker(options: options).check(
            required: relevant, provided: provided, mode: mode, roles: ATLFootprintExtractor.roles(of: module),
            footprint: footprint)
    }

    /// Checks an MTL module.
    ///
    /// - Parameters:
    ///   - module: The parsed module.
    ///   - metamodelName: The name under which diagnostics refer to the metamodel.
    ///   - required: The model type the module was written against.
    ///   - provided: The model type to check.
    ///   - mode: The subtyping relation to decide (default: ``SubtypingMode/partial``).
    ///   - options: The options of the check (default: standard options).
    /// - Returns: The report.
    public static func check(
        mtl module: MTLModule, metamodelName: String, required: ModelType, provided: ModelType,
        mode: SubtypingMode = .partial, options: CheckOptions = CheckOptions()
    ) -> CompatibilityReport {
        let binding = MetamodelBinding(name: metamodelName, modelType: required)
        let footprint = MTLFootprintExtractor(bindings: [binding]).footprint(of: module)
        return ModelTypeChecker(options: options).check(
            required: [metamodelName: required], provided: [metamodelName: provided], mode: mode,
            footprint: footprint)
    }

    /// Checks an AQL expression.
    ///
    /// - Parameters:
    ///   - expression: The parsed expression.
    ///   - variables: The written types of the free variables, such as `["self": "library::Library"]`.
    ///   - metamodelName: The name under which diagnostics refer to the metamodel.
    ///   - required: The model type the expression was written against.
    ///   - provided: The model type to check.
    ///   - mode: The subtyping relation to decide (default: ``SubtypingMode/partial``).
    ///   - options: The options of the check (default: standard options).
    /// - Returns: The report.
    public static func check(
        aql expression: any AQLExpression, variables: [String: String], metamodelName: String,
        required: ModelType, provided: ModelType, mode: SubtypingMode = .partial,
        options: CheckOptions = CheckOptions()
    ) -> CompatibilityReport {
        let binding = MetamodelBinding(name: metamodelName, modelType: required)
        let footprint = AQLFootprintExtractor(bindings: [binding]).footprint(of: expression, variables: variables)
        return ModelTypeChecker(options: options).check(
            required: [metamodelName: required], provided: [metamodelName: provided], mode: mode,
            footprint: footprint)
    }
}
