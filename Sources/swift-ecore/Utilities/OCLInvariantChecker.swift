//
// OCLInvariantChecker.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation
import ModellingGenerators
import OCL

/// An OCL invariant that a metamodel declares for a class.
struct OCLInvariant: Sendable, Equatable {
    /// The name of the invariant.
    let name: String

    /// The OCL expression that every instance of the class must satisfy.
    let expression: String

    /// The name of the class that declares the invariant.
    let context: String

    /// The invariants that a class declares itself, in declared order.
    ///
    /// The names come from the `constraints` detail of the annotation with the
    /// ``AnnotationSource/ecore`` source, and each expression from the detail of the same name of
    /// an annotation with an OCL source (see ``OCLVocabulary/annotationSources``). A class without
    /// the `constraints` detail declares every detail of its OCL annotation as an invariant.
    ///
    /// - Parameter eClass: The class.
    /// - Returns: The invariants with an expression.
    static func invariants(declaredBy eClass: EClass) -> [OCLInvariant] {
        let expressions = eClass.eAnnotations
            .filter { OCLVocabulary.annotationSources.contains($0.source) }
            .flatMap { $0.details.map { (key: $0.key, value: $0.value) } }
        guard !expressions.isEmpty else { return [] }
        let declared = eClass.getEAnnotationDetail(source: AnnotationSource.ecore, key: AnnotationSource.EcoreKey.constraints)
        let names = declared.map { $0.split(whereSeparator: OCLVocabulary.constraintNameSeparators.contains).map(String.init) }
            ?? expressions.map(\.key)
        return names.compactMap { name in
            expressions.first { $0.key == name }.map { OCLInvariant(name: name, expression: $0.value, context: eClass.name) }
        }
    }

    /// The invariants that apply to the instances of a class: those of its supertypes, then its own.
    ///
    /// - Parameters:
    ///   - eClass: The class.
    ///   - catalogue: The catalogue that holds the canonical definitions of the supertypes.
    /// - Returns: The invariants, those of the most general classes first.
    static func invariants(applyingTo eClass: EClass, catalogue: MetamodelCatalogue) -> [OCLInvariant] {
        let canonical = catalogue.canonical(eClass)
        let supertypes = canonical.eAllSuperTypes.map(catalogue.canonical)
        return (supertypes + [canonical]).flatMap(invariants(declaredBy:))
    }
}

/// The outcome of evaluating one invariant for one object.
struct ConstraintCheck: Codable, Sendable, Equatable {
    /// Whether an object satisfies an invariant.
    enum Outcome: String, Codable, Sendable {
        /// The invariant evaluates to `true`.
        case satisfied

        /// The invariant evaluates to anything but `true`.
        case violated

        /// The invariant cannot be parsed or evaluated.
        case failed

        /// The invariant uses an OCL construct that has no counterpart in AQL, so it is not
        /// evaluated.
        case untranslated
    }

    /// The name of the invariant.
    var constraint: String

    /// The name of the class that declares the invariant.
    var context: String

    /// The description of the object.
    var object: String

    /// The location of the object, such as `//@customers.0`.
    var location: String

    /// The outcome of the evaluation.
    var outcome: Outcome

    /// Why the invariant could not be evaluated, or what it evaluated to if not a Boolean.
    var detail: String?
}

/// Evaluates the OCL invariants of a metamodel for every object of a model.
///
/// Each invariant, whether the metamodel declares it or a Complete OCL document adds it, is
/// translated from OCL into AQL by `OCLToAQLTranslator`, which rewrites the constructs whose
/// meaning differs between the two languages, such as an explicit `self` inside an iteration,
/// the division of two integers and two-segment enumeration literals such as
/// `AccountType::SAVINGS`, and the AQL evaluator checks the translation. An invariant that uses
/// a construct without a counterpart in AQL, such as `iterate`, is reported as
/// ``ConstraintCheck/Outcome/untranslated`` instead of being evaluated. Text that is not OCL is
/// evaluated as AQL, as before. OCL's `String::indexOf`, which AQL does not offer, is added.
@MainActor
struct OCLInvariantChecker {
    /// The model to check.
    let document: ModelDocument

    /// The objects of the model.
    let objects: ModelCatalogue

    /// The classes of the metamodels.
    let catalogue: MetamodelCatalogue

    /// The behaviours of the expressions of the invariants.
    var aqlOptions: AQLOptions = .standard

    /// Evaluates every invariant that applies to every object of the model.
    ///
    /// On an interactive terminal, a progress bar shows how many objects have been checked.
    ///
    /// - Returns: One check per object and applicable invariant, in document order.
    func check() async -> [ConstraintCheck] {
        let pending = objects.entries.map { entry in
            (entry, OCLInvariant.invariants(applyingTo: objects.eClass(of: entry.object), catalogue: catalogue))
        }.filter { !$0.1.isEmpty }
        guard !pending.isEmpty else { return [] }
        let context = await makeContext()
        let translator = OCLToAQLTranslator(packages: document.describingPackages)
        let progress = GenerationProgressBar(verbose: false)
        var parsed: [String: Result<any AQLExpression, ParseFailure>] = [:]
        var checks: [ConstraintCheck] = []
        for (index, (entry, invariants)) in pending.enumerated() {
            progress.show(GenerationProgressUpdate(message: OCLVocabulary.progressMessage, completed: index, total: pending.count))
            for invariant in invariants {
                let key = invariant.context + "." + invariant.name
                let expression = parsed[key] ?? Self.parse(invariant.expression, translator: translator)
                parsed[key] = expression
                checks.append(await evaluate(invariant, expression, for: entry, in: context))
            }
        }
        progress.finish()
        return checks
    }

    /// Why an expression could not be parsed or translated.
    struct ParseFailure: Error {
        /// The message of the parser or the translator.
        let message: String

        /// Whether the expression is OCL that has no translation into AQL, rather than text
        /// that cannot be parsed.
        var isUntranslatable = false
    }

    /// Translates the OCL expression of an invariant into AQL and parses the translation.
    ///
    /// An expression that is not valid OCL is parsed as AQL, as it was before invariants were
    /// translated, so that invariants written in AQL keep working.
    ///
    /// - Parameters:
    ///   - source: The OCL text of the invariant.
    ///   - translator: The translator, which knows the packages of the metamodels.
    /// - Returns: The parsed AQL expression, or why there is none.
    static func parse(_ source: String, translator: OCLToAQLTranslator) -> Result<any AQLExpression, ParseFailure> {
        let translation = translator.translate(source)
        if let aql = translation.aql, case .success(let expression) = parse(aql) {
            return .success(expression)
        }
        let untranslatable = translation.diagnostics.filter { $0.code == OCLDiagnosticCode.untranslatable }
        guard untranslatable.isEmpty else {
            return .failure(
                ParseFailure(message: untranslatable.map(\.message).joined(separator: "; "), isUntranslatable: true))
        }
        return parse(source)
    }

    /// Parses an AQL expression.
    private static func parse(_ source: String) -> Result<any AQLExpression, ParseFailure> {
        let result = AQLParser().parse(source)
        guard let expression = result.expression, result.diagnostics.allSatisfy({ $0.severity != .error }) else {
            let message = result.diagnostics.map(\.message).joined(separator: "; ")
            return .failure(ParseFailure(message: message.isEmpty ? "cannot be parsed" : message))
        }
        return .success(expression)
    }

    /// Creates the context in which the invariants are evaluated.
    private func makeContext() async -> AQLExecutionContext {
        let engine = ECoreExecutionEngine(models: [:])
        await engine.registerResource(document.resource, alias: document.fileName)
        let context = AQLExecutionContext(executionEngine: engine, options: aqlOptions, serviceProviders: [OCLStringServices()])
        context.addResource(document.resource)
        return context
    }

    /// Evaluates one invariant for one object.
    private func evaluate(
        _ invariant: OCLInvariant, _ expression: Result<any AQLExpression, ParseFailure>,
        for entry: ModelCatalogue.Entry, in context: AQLExecutionContext
    ) async -> ConstraintCheck {
        var check = ConstraintCheck(
            constraint: invariant.name, context: invariant.context, object: objects.label(of: entry.object),
            location: entry.location, outcome: .failed)
        switch expression {
        case .failure(let failure):
            if failure.isUntranslatable { check.outcome = .untranslated }
            check.detail = failure.message
        case .success(let expression):
            context.setVariable(OCLVocabulary.selfVariable, value: entry.object)
            do {
                let value = try await expression.evaluate(in: context)
                if let satisfied = value as? Bool {
                    check.outcome = satisfied ? .satisfied : .violated
                } else {
                    check.outcome = .violated
                    check.detail = "evaluates to " + (value.map { ValueText.describe($0) } ?? "null")
                }
            } catch {
                check.detail = error.localizedDescription
            }
        }
        return check
    }
}

/// The OCL string operations that AQL does not offer.
struct OCLStringServices: AQLServiceProvider {
    /// The services offered.
    var services: [AQLService] {
        [
            AQLService(OCLVocabulary.indexOfOperation, receiver: .string, arity: 1...1) { call in
                let text = try call.receiverString()
                guard let range = text.range(of: try call.string(0)) else { return 0 }
                return text.distance(from: text.startIndex, to: range.lowerBound) + 1
            }
        ]
    }
}
