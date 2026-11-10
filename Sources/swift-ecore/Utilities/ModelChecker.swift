//
// ModelChecker.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import AQLMultiLevel
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import MultiLevel

/// What validation checks besides conformance.
struct ValidationOptions: Sendable, Equatable {
    /// Whether warnings count as errors.
    var strict = false

    /// Whether abstract classes and interfaces are checked explicitly.
    var checkAbstractClasses = false

    /// Whether OCL invariants reject the expressions that Eclipse AQL rejects.
    var strictAQL = false

    /// Whether every required single-valued feature needs a value that the model sets.
    ///
    /// When this is `false`, as in the Eclipse Modeling Framework, a required feature that the
    /// model leaves unset satisfies its lower bound when it reads as a default, such as the
    /// first literal of an enumeration or zero for a number. When it is `true`, such a feature
    /// is reported as having no value.
    var requiresExplicitValues = false

    /// Which references of a multi-level model may cross levels.
    var levelCrossing = LevelCrossingOptions.defaultMode
}

/// Checks a metamodel or a model and collects what is wrong with it.
///
/// A metamodel is checked against the constraints of Ecore. A model is always checked for
/// references into other documents that cannot be resolved. With a metamodel, a model is also
/// checked for classes and features that the metamodel does not define, for the bounds and
/// types of its features, for objects of abstract classes, and for the OCL invariants of the
/// metamodel. The multiplicities of features follow the Eclipse Modeling Framework: a required
/// feature that the model leaves unset is accepted when it reads as a default, unless
/// ``ValidationOptions/requiresExplicitValues`` asks for a value of its own.
@MainActor
struct ModelChecker {
    /// The document to check.
    let document: ModelDocument

    /// What to check besides conformance.
    let options: ValidationOptions

    /// The findings, abstract class summaries and invariant evaluations of a validation.
    struct Outcome: Sendable {
        /// The problems found.
        var findings: [ValidationFinding] = []

        /// The abstract classes that were checked, if asked for on a metamodel.
        var abstractClasses: [AbstractClassSummary]?

        /// The evaluated invariants, if the metamodel declares any.
        var constraints: [ConstraintCheck]?
    }

    /// Runs every check that applies to the document.
    ///
    /// - Returns: What the checks found.
    func check() async -> Outcome {
        if let deepModel = document.deepModel { return await checkDeepModel(deepModel) }
        return document.isMetamodel ? checkMetamodel() : await checkModel()
    }

    // MARK: - Multi-level models

    /// Checks a multi-level model: its structure, its level crossings under
    /// ``ValidationOptions/levelCrossing``, and its constraints, which are evaluated with AQL on
    /// the deep instances at the levels that their potencies select.
    ///
    /// - Parameter model: The multi-level model of the document.
    /// - Returns: What the checks found.
    private func checkDeepModel(_ model: DeepModel) async -> Outcome {
        var model = model
        model.levelCrossing = options.levelCrossing.policy
        let evaluator = AQLDeepConstraintEvaluator(options: AQLOptions(strict: options.strictAQL))
        let diagnostics = await model.validate(evaluator: evaluator) + options.levelCrossing.diagnostics(for: model)
        var outcome = Outcome()
        outcome.findings = diagnostics.map { diagnostic in
            ValidationFinding(
                severity: Self.severity(of: diagnostic.severity), code: diagnostic.code,
                location: diagnostic.range.map { "\($0.start.line):\($0.start.column)" }, message: diagnostic.message)
        }
        return outcome
    }

    // MARK: - Metamodels

    /// Checks a metamodel against the constraints of Ecore.
    private func checkMetamodel() -> Outcome {
        let index = MetamodelIndex(roots: document.packages)
        var outcome = Outcome()
        for diagnostic in EcoreValidator().validate(index) {
            outcome.findings.append(
                ValidationFinding(
                    severity: Self.severity(of: diagnostic.severity), code: "ecore.\(diagnostic.code.rawValue)",
                    location: index.fragment(of: diagnostic.element), message: diagnostic.message))
        }
        if options.checkAbstractClasses {
            let catalogue = MetamodelCatalogue(roots: document.packages)
            var summaries: [AbstractClassSummary] = []
            for eClass in catalogue.classes where eClass.isAbstract || eClass.isInterface {
                let concrete = catalogue.allSubclasses(of: eClass).filter { !$0.isAbstract && !$0.isInterface }
                summaries.append(
                    AbstractClassSummary(name: eClass.name, interface: eClass.isInterface, concreteSubclasses: concrete.map(\.name)))
                if concrete.isEmpty {
                    outcome.findings.append(
                        ValidationFinding(
                            severity: .warning, code: ValidationCode.abstractWithoutConcreteSubclass,
                            location: index.fragment(of: eClass.id), element: eClass.name,
                            message: "No concrete class extends \(eClass.name), so no object can be an instance of it"))
                }
            }
            outcome.abstractClasses = summaries
        }
        return outcome
    }

    // MARK: - Models

    /// Checks a model.
    private func checkModel() async -> Outcome {
        let objects = await ModelCatalogue.build(for: document)
        let catalogue = MetamodelCatalogue(roots: document.metamodels)
        var outcome = Outcome()
        outcome.findings += parserFindings()
        outcome.findings += await crossDocumentFindings(objects: objects, catalogue: catalogue)
        guard document.hasMetamodel else {
            if options.checkAbstractClasses {
                outcome.findings.append(
                    ValidationFinding(
                        severity: .warning, code: ValidationCode.abstractClassesUnknown,
                        message: "Without a metamodel, it is unknown which classes are abstract; give one with --metamodel"))
            }
            return outcome
        }
        outcome.findings += undefinedFeatureFindings(objects: objects)
        let snapshot = await document.resource.snapshot()
        let validator = ModelValidator(
            metamodels: document.metamodels,
            options: ModelValidator.Options(requiresExplicitValues: options.requiresExplicitValues))
        for diagnostic in validator.validate(snapshot) {
            let entry = objects.entry(for: diagnostic.objectID)
            outcome.findings.append(
                ValidationFinding(
                    severity: Self.severity(of: diagnostic.severity), code: diagnostic.code.rawValue,
                    location: entry?.location, element: entry.map { objects.label(of: $0.object) },
                    message: diagnostic.message))
        }
        if options.checkAbstractClasses {
            let abstract = objects.entries.filter {
                let eClass = objects.eClass(of: $0.object)
                return eClass.isAbstract || eClass.isInterface
            }
            if abstract.isEmpty {
                outcome.findings.append(
                    ValidationFinding(
                        severity: .information, code: ValidationCode.noAbstractInstances,
                        message: "No object is an instance of an abstract class or an interface"))
            }
        }
        let checks = await OCLInvariantChecker(
            document: document, objects: objects, catalogue: catalogue,
            aqlOptions: AQLOptions(strict: options.strictAQL)
        ).check()
        if !checks.isEmpty {
            outcome.constraints = checks
            for check in checks where check.outcome != .satisfied {
                outcome.findings.append(
                    ValidationFinding(
                        severity: check.outcome == .untranslated ? .warning : .error, code: ValidationCode.invariant,
                        location: check.location, element: check.object,
                        message: "Invariant \(check.context)::\(check.constraint) is \(check.outcome.rawValue)"
                            + (check.detail.map { " (\($0))" } ?? "") + (check.message.map { ": " + $0 } ?? "")))
            }
        }
        return outcome
    }

    /// The problems that the parser recorded.
    ///
    /// A class that no metamodel defines is an error when the model is read with a metamodel,
    /// and expected when it is read without one.
    private func parserFindings() -> [ValidationFinding] {
        document.diagnostics.warnings.compactMap { warning in
            if case .untypedClass(let name) = warning.kind {
                guard document.hasMetamodel else { return nil }
                return ValidationFinding(
                    severity: .error, code: ValidationCode.undefinedClass, element: name,
                    message: "No metamodel defines the class \(name)")
            }
            return ValidationFinding(severity: .warning, code: ValidationCode.parser, message: warning.message)
        }
    }

    /// The features that objects set but their classes do not define.
    private func undefinedFeatureFindings(objects: ModelCatalogue) -> [ValidationFinding] {
        objects.entries.flatMap { entry -> [ValidationFinding] in
            let eClass = objects.eClass(of: entry.object)
            let defined = Set(eClass.eAllStructuralFeatures.map(\.name))
            return entry.object.getFeatureNames().filter { !defined.contains($0) }.map { name in
                ValidationFinding(
                    severity: .error, code: ValidationCode.undefinedFeature, location: entry.location,
                    element: objects.label(of: entry.object), message: "Class \(eClass.name) defines no feature '\(name)'")
            }
        }
    }

    /// The references into other documents that cannot be resolved or lead to objects of the
    /// wrong class.
    private func crossDocumentFindings(objects: ModelCatalogue, catalogue: MetamodelCatalogue) async -> [ValidationFinding] {
        var findings: [ValidationFinding] = []
        for entry in objects.entries {
            let eClass = objects.eClass(of: entry.object)
            for name in entry.object.getFeatureNames() {
                let proxies = ValueElements.of(entry.object.eGet(name)).compactMap { $0 as? ResourceProxy }
                let reference = MetamodelCatalogue.references(of: eClass).first { $0.name == name }
                for proxy in proxies {
                    let target = ModelCatalogue.text(of: proxy)
                    guard let resolved = await proxy.resolveObject(in: document.resourceSet) else {
                        findings.append(await Self.unresolvedFinding(
                            proxy, reference: name, target: target, in: document.resourceSet,
                            location: entry.location, element: objects.label(of: entry.object)))
                        continue
                    }
                    guard let expected = (reference?.eType as? EClass).map(catalogue.canonical),
                        let actual = (resolved.eClass as? EClass).map(catalogue.canonical),
                        !Self.isInstance(actual, of: expected)
                    else { continue }
                    findings.append(
                        ValidationFinding(
                            severity: .error, code: ValidationCode.referenceTypeMismatch, location: entry.location,
                            element: objects.label(of: entry.object),
                            message: "Reference '\(name)' names \(target), an instance of \(actual.name), which is not a \(expected.name)"))
                }
            }
        }
        return findings
    }

    /// The finding for a reference into another document that names no object.
    ///
    /// A reference into a document of the Eclipse platform, such as a UML profile or library
    /// with a `pathmap:` URI, that cannot be read is a warning: the document is not available
    /// here, so the reference cannot be checked. Any other unresolved reference, including one
    /// into a document that can be read but has no such object, is an error.
    ///
    /// - Parameters:
    ///   - proxy: The unresolved reference.
    ///   - reference: The name of the reference feature.
    ///   - target: The text of the reference.
    ///   - resourceSet: The resource set in which the reference was resolved.
    ///   - location: Where the referring object is.
    ///   - element: The label of the referring object.
    /// - Returns: The finding.
    private static func unresolvedFinding(
        _ proxy: ResourceProxy, reference: String, target: String, in resourceSet: ResourceSet,
        location: String?, element: String
    ) async -> ValidationFinding {
        let isPlatformDocument = proxy.uri.hasPrefix(ValidationCode.platformDocumentPrefix)
        if isPlatformDocument, await proxy.targetResource(in: resourceSet) == nil {
            return ValidationFinding(
                severity: .warning, code: ValidationCode.unavailableDocument, location: location, element: element,
                message: "Reference '\(reference)' names \(target), whose document \(proxy.uri) is not available, "
                    + "so the reference is not checked")
        }
        return ValidationFinding(
            severity: .error, code: ValidationCode.unresolvedReference, location: location, element: element,
            message: "Reference '\(reference)' names \(target), which does not exist")
    }

    /// Whether a class is a class or a subclass of another, compared by name across documents.
    private static func isInstance(_ candidate: EClass, of expected: EClass) -> Bool {
        candidate.name == expected.name || expected.name == EcoreClassifier.eObject.rawValue
            || candidate.eAllSuperTypes.contains { $0.name == expected.name }
    }

    /// The severity of a finding for the severity of a library diagnostic.
    private static func severity(of severity: DiagnosticSeverity) -> ValidationFinding.Severity {
        switch severity {
        case .error: return .error
        case .warning: return .warning
        default: return .information
        }
    }
}

/// The identifiers of the checks that the command performs itself.
///
/// The checks of the library keep their own identifiers, such as `model.lowerBound` or
/// `ecore.WellFormedName`.
enum ValidationCode {
    /// The parser recorded a problem.
    static let parser = "model.parser"

    /// No metamodel defines the class of an object.
    static let undefinedClass = "model.undefinedClass"

    /// The class of an object defines no feature of that name.
    static let undefinedFeature = "model.undefinedFeature"

    /// A reference into another document names no object.
    static let unresolvedReference = "model.unresolvedReference"

    /// A reference into a document of the Eclipse platform names a document that is not
    /// available.
    static let unavailableDocument = "model.unavailableDocument"

    /// The start of the URIs by which models refer to documents of the Eclipse platform, such
    /// as the libraries and profiles of Eclipse UML2.
    static let platformDocumentPrefix = "pathmap://"

    /// A reference into another document names an object of the wrong class.
    static let referenceTypeMismatch = "model.crossReferenceTypeMismatch"

    /// An object does not satisfy an OCL invariant.
    static let invariant = "ocl.invariant"

    /// No concrete class extends an abstract class or interface.
    static let abstractWithoutConcreteSubclass = "metamodel.abstractWithoutConcreteSubclass"

    /// Abstract classes cannot be checked without a metamodel.
    static let abstractClassesUnknown = "model.abstractClassesUnknown"

    /// No object is an instance of an abstract class or interface.
    static let noAbstractInstances = "model.noAbstractInstances"
}
