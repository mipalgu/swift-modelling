//
// InvariantTranslator.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// Translates the OCL invariants of a metamodel to the formulas of a verification target.
///
/// The translator reads the invariants of a class from its annotations, checks them against the
/// metamodel and prints the result in the notation of the target, quantified over all instances
/// of the class. Invariants outside the translatable subset of OCL are reported with the reason,
/// so that the exports can list them as not exported.
///
/// ## Example
///
/// ```swift
/// let translator = InvariantTranslator(packages: [package])
/// switch translator.translate(className: "Member", constraint: "NonNegativeAge", target: .alloy) {
/// case .success(let formula): print(formula)   // all self: Member | self.age >= 0
/// case .failure(let error): print(error.reason)
/// }
/// ```
struct InvariantTranslator: Sendable {
    /// The packages whose classes the translator knows, nested packages included.
    let packages: [EPackage]

    /// The metamodel index used to resolve navigations.
    let index: MetamodelIndex

    /// Creates a translator for the classes of packages.
    ///
    /// - Parameter packages: The packages of the metamodel.
    init(packages: [EPackage]) {
        self.packages = packages
        self.index = MetamodelIndex(packages: packages)
    }

    /// The invariants that a class declares, in the order in which it names them.
    ///
    /// - Parameter className: The name of the class.
    /// - Returns: The invariants, or none if the class is unknown.
    func invariants(of className: String) -> [Invariant] {
        guard let (eClass, package) = find(className) else { return [] }
        return InvariantCatalogue.invariants(of: eClass, in: package)
    }

    /// Translates a named invariant of a class.
    ///
    /// - Parameters:
    ///   - className: The name of the class that declares the invariant.
    ///   - constraint: The name of the constraint.
    ///   - target: The verification target.
    ///   - primed: The identifiers of classes and features that are written with a prime, as in
    ///     the before-after predicates of Event-B; empty by default.
    /// - Returns: The formula, quantified over the instances of the class, or the reason why the
    ///   invariant cannot be translated.
    func translate(
        className: String, constraint: String, target: VerificationTarget, primed: Set<String> = []
    ) -> Result<String, TranslationError> {
        guard let invariant = invariants(of: className).first(where: { $0.name == constraint }),
            let body = invariant.body
        else { return .failure(TranslationError("the constraint '\(constraint)' has no OCL body")) }
        return translate(text: body, className: className, target: target, primed: primed)
    }

    /// Translates the text of an invariant of a class.
    ///
    /// - Parameters:
    ///   - text: The OCL text of the invariant.
    ///   - className: The name of the class that the invariant constrains.
    ///   - target: The verification target.
    ///   - primed: The identifiers of classes and features that are written with a prime; empty
    ///     by default.
    /// - Returns: The formula, quantified over the instances of the class, or the reason why the
    ///   invariant cannot be translated.
    func translate(
        text: String, className: String, target: VerificationTarget, primed: Set<String> = []
    ) -> Result<String, TranslationError> {
        Result {
            let term = try OCLTypeChecker(index: index).check(text, context: className)
            switch target {
            case .alloy: return try AlloyFormulaPrinter(target: target).invariant(term, className: className)
            case .tla: return try TLAFormulaPrinter(target: target).invariant(term, className: className)
            case .eventB:
                return try EventBFormulaPrinter(target: target, primed: primed).invariant(term, className: className)
            case .lean: return try LeanFormulaPrinter(target: target).invariant(term, className: className)
            }
        }.mapError { $0 as? TranslationError ?? TranslationError(String(describing: $0)) }
    }

    private func find(_ className: String) -> (EClass, EPackage)? {
        var stack = packages
        while let package = stack.popLast() {
            if let eClass = package.eClassifiers.first(where: { $0.name == className }) as? EClass {
                return (eClass, package)
            }
            stack.append(contentsOf: package.eSubpackages)
        }
        return nil
    }
}

/// Helpers shared by the printers of the targets.
///
/// The printers compare the values of a body for two elements of a collection when they translate
/// `isUnique`, which needs the body with its iterator renamed.
extension OCLTerm {
    /// Renames a variable throughout the term.
    ///
    /// Variables bound by an inner quantifier with the same name are left alone, so that the
    /// renaming respects scope. The printers use it to compare two copies of an iterator.
    ///
    /// - Parameters:
    ///   - name: The variable to replace.
    ///   - replacement: The name to use instead.
    /// - Returns: The term with every occurrence of the variable renamed.
    func renaming(_ name: String, to replacement: String) -> OCLTerm {
        func r(_ term: OCLTerm) -> OCLTerm { term.renaming(name, to: replacement) }
        let node: Node
        switch self.node {
        case .variable(let variable): node = .variable(variable == name ? replacement : variable)
        case .boolean, .integer, .string, .enumLiteral, .allInstances: node = self.node
        case .navigation(let source, let feature): node = .navigation(r(source), feature)
        case .collectedNavigation(let source, let feature): node = .collectedNavigation(r(source), feature)
        case .not(let operand): node = .not(r(operand))
        case .negate(let operand): node = .negate(r(operand))
        case .binary(let op, let left, let right): node = .binary(op, r(left), r(right))
        case .equality(let left, let right, let negated): node = .equality(r(left), r(right), negated: negated)
        case .undefined(let operand, let negated): node = .undefined(r(operand), negated: negated)
        case .size(let operand): node = .size(r(operand))
        case .isEmpty(let operand, let negated): node = .isEmpty(r(operand), negated: negated)
        case .includes(let collection, let element, let negated):
            node = .includes(r(collection), r(element), negated: negated)
        case .quantified(let quantifier, let variable, let source, let body):
            node = .quantified(quantifier, variable: variable, source: r(source), body: variable == name ? body : r(body))
        case .filtered(let variable, let source, let body, let keeps):
            node = .filtered(variable: variable, source: r(source), body: variable == name ? body : r(body), keeps: keeps)
        case .unique(let variable, let source, let body):
            node = .unique(variable: variable, source: r(source), body: variable == name ? body : r(body))
        case .kindOf(let operand, let className): node = .kindOf(r(operand), className)
        case .conditional(let condition, let then, let otherwise): node = .conditional(r(condition), r(then), r(otherwise))
        }
        return OCLTerm(node, kind: kind, multiplicity: multiplicity)
    }

    /// The names of the two copies of an iterator that a uniqueness check compares.
    ///
    /// - Parameter variable: The name of the iterator.
    /// - Returns: The names of the first and second copy.
    static func uniquenessCopies(of variable: String) -> (String, String) {
        (variable + VerificationVocabulary.qualifier + "1", variable + VerificationVocabulary.qualifier + "2")
    }
}
