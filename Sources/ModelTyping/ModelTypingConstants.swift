//
//  ModelTypingConstants.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

/// The authoritative vocabulary that model typing relies on.
///
/// Every name with a semantic meaning (type syntax, standard service names,
/// Ecore data type names and the canonical data type categories) is defined
/// here once, so that footprint extraction and subtyping checks agree on it.
public enum ModelTypingVocabulary {

    /// The separator between a metamodel name and a classifier name in ATL (`MM!Class`).
    public static let atlTypeSeparator = "!"

    /// The separator between a package name and a classifier name in AQL and MTL (`pkg::Class`).
    public static let aqlTypeSeparator = "::"

    /// The separator between a class name and a feature name in renaming keys (`Class.feature`).
    public static let featureSeparator = "."

    /// The separator between an enumeration name and a literal name in renaming keys (`Enum.literal`).
    public static let literalSeparator = "."

    /// The variable that denotes the context object of a helper, template or implicit iterator.
    public static let selfVariable = "self"

    /// The ATL variable that denotes the transformation module itself.
    public static let thisModuleVariable = "thisModule"

    /// The collection type constructors recognised in written type names.
    public static let collectionTypeConstructors: Set<String> = [
        "Sequence", "Set", "OrderedSet", "Bag", "Collection",
    ]

    /// The primitive type names of OCL, ATL, AQL and MTL.
    public static let primitiveTypeNames: Set<String> = [
        "String", "Integer", "Boolean", "Real", "OclAny", "OclVoid", "OclType", "EObject", "Map",
        "TupleType", "Tuple",
    ]

    /// The `allInstances` family of operations, which read every instance of a type.
    public static let allInstancesOperations: Set<String> = ["allInstances", "allInstancesFrom"]

    /// Operations whose first argument is a type that the receiver is tested against or cast to.
    public static let typeTestOperations: Set<String> = ["oclIsKindOf", "oclIsTypeOf"]

    /// Operations that cast their receiver to the type given as their first argument.
    public static let typeCastOperations: Set<String> = ["oclAsType"]

    /// Operations that keep the elements of the receiver that have the type given as their argument.
    public static let typeFilterOperations: Set<String> = ["filter", "selectByKind", "selectByType"]

    /// Containment traversal operations that, given a type argument, yield a collection of that type.
    public static let typedTraversalOperations: Set<String> = [
        "eAllContents", "eContents", "eInverse", "ancestors", "siblings", "precedingSiblings",
        "followingSiblings",
    ]

    /// Operations that yield the container of the receiver, optionally restricted to a type argument.
    public static let containerOperations: Set<String> = ["eContainer", "eContainerOrSelf", "refImmediateComposite"]

    /// Iterator operations whose result is a collection of the receiver's elements.
    public static let elementPreservingIterators: Set<String> = [
        "select", "reject", "sortedBy", "closure",
    ]

    /// Iterator operations whose result is a collection of the iterator body's values.
    public static let collectingIterators: Set<String> = ["collect", "collectNested"]

    /// Iterator operations whose result is one element of the receiver.
    public static let elementSelectingIterators: Set<String> = ["any", "detect"]

    /// Operations whose result is a collection of the receiver's elements.
    public static let elementPreservingOperations: Set<String> = [
        "asSet", "asSequence", "asOrderedSet", "asBag", "reverse", "including", "excluding",
        "union", "intersection", "subSequence", "subOrderedSet", "includingAll", "excludingAll",
        "append", "prepend", "insertAt", "add", "sub", "symmetricDifference", "sep", "drop",
        "dropRight", "removeAll",
    ]

    /// Operations whose result is one element of the receiver.
    public static let elementSelectingOperations: Set<String> = ["first", "last", "at", "lastIndexOf"]

    /// Operations that flatten nested collections.
    public static let flatteningOperations: Set<String> = ["flatten"]

    /// Operations with a Boolean result.
    public static let booleanOperations: Set<String> = [
        "oclIsUndefined", "oclIsInvalid", "isEmpty", "notEmpty", "includes", "excludes",
        "includesAll", "excludesAll", "exists", "forAll", "one", "isUnique", "startsWith",
        "endsWith", "contains", "matches", "equalsIgnoreCase", "isEven", "isOdd", "not", "and",
        "or", "xor", "implies", "oclIsKindOf", "oclIsTypeOf", "isOclKindOf",
    ]

    /// Operations with an Integer result.
    public static let integerOperations: Set<String> = [
        "size", "indexOf", "count", "toInteger", "length", "floor", "round", "div", "mod", "abs",
        "power",
    ]

    /// Operations with a String result.
    public static let stringOperations: Set<String> = [
        "toString", "toUpper", "toLower", "toUpperCase", "toLowerCase", "toUpperFirst",
        "toLowerFirst", "concat", "substring", "trim", "replace", "replaceAll", "prefix",
        "lineSeparator", "tokenize", "strip",
    ]

    /// Canonical data type categories of the Ecore data types and their common aliases.
    ///
    /// The keys are names as written in metamodels (Ecore names, Java instance class
    /// names, OCL names); the values are the canonical category used for comparison.
    public static let canonicalDataTypes: [String: CanonicalDataType] = [
        "EString": .string, "String": .string, "java.lang.String": .string,
        "EBoolean": .boolean, "EBooleanObject": .boolean, "boolean": .boolean,
        "java.lang.Boolean": .boolean, "Boolean": .boolean,
        "EByte": .integer8, "EByteObject": .integer8, "byte": .integer8, "java.lang.Byte": .integer8,
        "EShort": .integer16, "EShortObject": .integer16, "short": .integer16,
        "java.lang.Short": .integer16,
        "EInt": .integer32, "EIntegerObject": .integer32, "int": .integer32,
        "java.lang.Integer": .integer32, "Integer": .integer32,
        "ELong": .integer64, "ELongObject": .integer64, "long": .integer64,
        "java.lang.Long": .integer64,
        "EBigInteger": .bigInteger, "java.math.BigInteger": .bigInteger,
        "EFloat": .real32, "EFloatObject": .real32, "float": .real32, "java.lang.Float": .real32,
        "EDouble": .real64, "EDoubleObject": .real64, "double": .real64,
        "java.lang.Double": .real64, "Real": .real64,
        "EBigDecimal": .decimal, "java.math.BigDecimal": .decimal,
        "EChar": .character, "ECharacterObject": .character, "char": .character,
        "java.lang.Character": .character,
        "EDate": .date, "java.util.Date": .date,
        "EByteArray": .byteArray, "byte[]": .byteArray,
        "EJavaObject": .any, "java.lang.Object": .any,
    ]
}

/// A canonical category of data type values.
///
/// Different spellings of the same value domain (for example `EInt`,
/// `EIntegerObject`, `int` and `java.lang.Integer`) share one category, so that
/// attribute types can be compared independently of how a metamodel names them.
public enum CanonicalDataType: String, Sendable, Hashable, CaseIterable, Codable {
    /// Character strings.
    case string
    /// Truth values.
    case boolean
    /// Signed 8-bit integers.
    case integer8
    /// Signed 16-bit integers.
    case integer16
    /// Signed 32-bit integers.
    case integer32
    /// Signed 64-bit integers.
    case integer64
    /// Integers of arbitrary size.
    case bigInteger
    /// Single precision floating point numbers.
    case real32
    /// Double precision floating point numbers.
    case real64
    /// Decimal numbers of arbitrary precision.
    case decimal
    /// Single characters.
    case character
    /// Points in time.
    case date
    /// Byte sequences.
    case byteArray
    /// Arbitrary values.
    case any

    /// The widening chain this category belongs to, in increasing order of range.
    ///
    /// A value of one category can be represented without loss by every later
    /// category of the same chain. Categories that cannot be widened belong to
    /// a chain of their own.
    public var wideningChain: [CanonicalDataType] {
        switch self {
        case .integer8, .integer16, .integer32, .integer64, .bigInteger:
            return [.integer8, .integer16, .integer32, .integer64, .bigInteger]
        case .real32, .real64, .decimal:
            return [.real32, .real64, .decimal]
        default:
            return [self]
        }
    }

    /// Whether every value of this category can be represented by another category.
    ///
    /// - Parameter other: The category that would receive the value.
    /// - Returns: `true` if `other` is this category or a wider one in the same chain.
    public func widens(to other: CanonicalDataType) -> Bool {
        let chain = wideningChain
        guard let from = chain.firstIndex(of: self), let to = chain.firstIndex(of: other) else {
            return false
        }
        return from <= to
    }
}
