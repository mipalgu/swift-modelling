//
// VerificationVocabulary.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The fixed words and sources that the verification exports rely on.
///
/// Keeping them in one place makes sure that the translation of invariants, the services offered
/// to templates and the tests agree.
enum VerificationVocabulary {
    /// The suffix that makes a reserved word usable as an identifier.
    static let reservedSuffix = "_"

    /// The separator between a qualifying name and a qualified name, such as an enumeration and
    /// its literal.
    static let qualifier = "_"

    /// The source of the Ecore annotation that names the constraints of a classifier.
    static let ecoreAnnotationSource = "http://www.eclipse.org/emf/2002/Ecore"

    /// The key of the Ecore annotation detail that lists the constraints of a classifier.
    static let constraintsKey = "constraints"

    /// The key of the Ecore annotation detail that lists the validation delegates of a package.
    static let validationDelegatesKey = "validationDelegates"

    /// The annotation sources of the OCL validation delegates, searched for constraint bodies
    /// after the delegates that a package declares.
    static let oclDelegateSources = [
        "http://www.eclipse.org/emf/2002/Ecore/OCL/Pivot",
        "http://www.eclipse.org/emf/2002/Ecore/OCL",
        "http://www.eclipse.org/ocl/examples/OCL",
    ]

    /// The name of the variable that denotes the constrained object in an invariant.
    static let selfName = "self"

    /// The Ecore data types whose values are integers.
    static let integerTypes: Set<String> = [
        "EInt", "EIntegerObject", "ELong", "ELongObject", "EShort", "EShortObject", "EByte",
        "EByteObject", "EBigInteger",
    ]

    /// The Ecore data types whose values are truth values.
    static let booleanTypes: Set<String> = ["EBoolean", "EBooleanObject"]

    /// The Ecore data types whose values are text.
    static let stringTypes: Set<String> = ["EString", "EChar", "ECharacterObject"]

    /// The instance class names of data types whose values are integers.
    static let integerInstanceClasses: Set<String> = [
        "int", "long", "short", "byte", "java.lang.Integer", "java.lang.Long", "java.lang.Short",
        "java.lang.Byte", "java.math.BigInteger",
    ]

    /// The instance class names of data types whose values are truth values.
    static let booleanInstanceClasses: Set<String> = ["boolean", "java.lang.Boolean"]

    /// The instance class names of data types whose values are text.
    static let stringInstanceClasses: Set<String> = ["java.lang.String", "char", "java.lang.Character"]

    /// Words reserved in Alloy 6, including its temporal keywords, built-in signatures and the
    /// names that the export declares.
    static let alloyReservedWords: Set<String> = [
        "abstract", "after", "all", "always", "and", "as", "assert", "before", "but", "check",
        "disj", "else", "enabled", "event", "eventually", "exactly", "expect", "extends", "fact",
        "for", "fun", "historically", "iden", "iff", "implies", "in", "Int", "int", "let", "lone",
        "module", "no", "none", "not", "once", "one", "open", "or", "pred", "private", "releases",
        "run", "seq", "set", "sig", "since", "some", "steps", "String", "sum", "this", "triggered",
        "univ", "until", "var", "Bool", "True", "False", "EObject", "contents", "invariants",
        "Inheritance", "Multiplicities", "Opposites", "Containment", "Model", "instance", "conforms",
    ]

    /// Words reserved in TLA+, including the operators of the standard modules that the export
    /// extends and the names that the export declares.
    static let tlaReservedWords: Set<String> = [
        "ASSUME", "ASSUMPTION", "AXIOM", "BOOLEAN", "CASE", "CHOOSE", "CONSTANT", "CONSTANTS",
        "DOMAIN", "ELSE", "ENABLED", "EXCEPT", "EXTENDS", "FALSE", "IF", "IN", "INSTANCE", "LET",
        "LOCAL", "MODULE", "OTHER", "SF_", "STRING", "SUBSET", "THEN", "THEOREM", "TRUE", "UNCHANGED",
        "UNION", "VARIABLE", "VARIABLES", "WF_", "WITH", "Int", "Nat", "Cardinality", "IsFiniteSet",
        "Null", "Object", "obj", "Opt", "TypeOK", "WellFormed", "Contents", "Init", "Next", "Spec",
        "Multiplicities", "Opposites", "Containment", "Invariants", "Seq", "Any", "Print", "Assert",
    ]

    /// Words reserved in Event-B, including the keywords of the textual notation and the names
    /// that the export declares.
    static let eventBReservedWords: Set<String> = [
        "BOOL", "FALSE", "INT", "NAT", "NAT1", "POW", "POW1", "TRUE", "bool", "card", "dom",
        "finite", "id", "inter", "max", "min", "mod", "partition", "pred", "prj1", "prj2", "ran",
        "succ", "union", "context", "machine", "sets", "constants", "axioms", "variables",
        "invariants", "events", "event", "end", "then", "where", "any", "with", "sees", "extends",
        "refines", "OBJECT", "STRING", "contents", "when", "begin", "variant", "set", "axiom",
        "theorem", "ordinary", "convergent", "anticipated", "status", "witness",
    ]

    /// Keywords of Lean 4, which identifiers can only use when enclosed in guillemets.
    static let leanReservedWords: Set<String> = [
        "abbrev", "at", "attribute", "axiom", "break", "by", "calc", "catch", "class", "continue",
        "decreasing_by", "deriving", "def", "do", "elab", "else", "end", "example", "export",
        "extends", "finally", "for", "from", "fun", "have", "if", "import", "in", "include",
        "inductive", "infix", "initialize", "instance", "let", "local", "macro", "match", "meta",
        "mut", "mutual", "namespace", "noncomputable", "nofun", "nomatch", "nonrec", "notation",
        "omit", "opaque", "open", "partial", "postfix", "prefix", "private", "protected", "Prop",
        "public", "return", "scoped", "section", "set_option", "show", "Sort", "sorry",
        "structure", "suffices", "syntax", "termination_by", "then", "theorem", "try", "Type",
        "universe", "unless", "unsafe", "using", "variable", "where", "with",
    ]

    /// The names that the Lean export declares itself, which model names must not take over.
    ///
    /// Guillemets do not change a name in Lean, so these names get a trailing underscore instead.
    static let leanDeclaredNames: Set<String> = [
        "Obj", "Model", "ObjectId", "WellFormed", "Invariants", "optEq", "optNe", "optLt", "optLe",
        "optGt", "optGe", "optAdd", "optSub", "optMul", "optDiv", "optMod", "optNeg", "optContains",
        "allDistinct", "model", "wellFormed",
    ]
}
