//
// GenModelServiceName.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// The single authoritative list of the names under which the generator model services are offered to templates.
///
/// Templates call these as `receiver.name(arguments)`, `receiver->name(arguments)` or, for services
/// without parameters, as the property `receiver.name`. The names are language neutral; the
/// services behind them know nothing about any target language.
public enum GenModelServiceName {
    // MARK: Names

    /// The name of the Ecore element that a generator element describes.
    public static let name = "name"
    /// The name with its first character capitalised.
    public static let capName = "capName"
    /// The name with its first character lowercased.
    public static let uncapName = "uncapName"
    /// The name with its leading capitals lowercased.
    public static let uncapPrefixedName = "uncapPrefixedName"
    /// The name in upper case with words separated by underscores.
    public static let upperName = "upperName"
    /// The name split into words with a separator.
    public static let formatName = "formatName"

    // MARK: Navigation

    /// The generator model that owns an element.
    public static let genModel = "genModel"
    /// The generator package that owns an element.
    public static let genPackage = "genPackage"
    /// The generator package that contains a nested package.
    public static let parentGenPackage = "parentGenPackage"
    /// The generator class that owns a feature or operation.
    public static let genClass = "genClass"
    /// The element that directly contains an element.
    public static let container = "genContainer"
    /// The packages of a model including nested packages.
    public static let allGenPackages = "allGenPackages"
    /// The classifiers of a package in identifier order.
    public static let genClassifiers = "genClassifiers"
    /// The classes of a package ordered by their first base class.
    public static let orderedGenClasses = "orderedGenClasses"
    /// The classifiers of a package in dependency order.
    public static let orderedGenClassifiers = "orderedGenClassifiers"

    // MARK: Classes and features

    /// All features of a class including inherited ones.
    public static let allGenFeatures = "allGenFeatures"
    /// The features that a class inherits.
    public static let inheritedGenFeatures = "inheritedGenFeatures"
    /// The features that a class implements itself.
    public static let implementedGenFeatures = "implementedGenFeatures"
    /// All operations of a class including inherited ones.
    public static let allGenOperations = "allGenOperations"
    /// The generator classes of the direct supertypes.
    public static let baseGenClasses = "baseGenClasses"
    /// The generator classes of all supertypes.
    public static let allBaseGenClasses = "allBaseGenClasses"
    /// The generator class of the first supertype.
    public static let baseGenClass = "baseGenClass"
    /// The class that a class extends in single inheritance languages.
    public static let classExtendsGenClass = "classExtendsGenClass"
    /// The classes whose features a class implements itself.
    public static let implementedGenClasses = "implementedGenClasses"
    /// The numeric identifier of a feature within a class.
    public static let featureID = "featureID"
    /// The number of features of a class including inherited ones.
    public static let featureCount = "featureCount"
    /// The numeric identifier of an operation within a class.
    public static let operationID = "operationID"
    /// The number of operations of a class including inherited ones.
    public static let operationCount = "operationCount"
    /// The numeric identifier of a classifier within its package.
    public static let classifierID = "classifierID"
    /// The symbolic identifier of a classifier.
    public static let classifierIDName = "classifierIDName"
    /// Whether a class is a map entry class.
    public static let isMapEntry = "isMapEntry"
    /// The feature that labels instances of a class.
    public static let labelFeature = "labelFeature"
    /// The literals of an enumeration that share no value with an earlier literal.
    public static let uniqueValuedGenEnumLiterals = "uniqueValuedGenEnumLiterals"
    /// Whether the class of a generator class is an interface.
    public static let isInterface = "isInterface"
    /// Whether the class of a generator class is abstract or an interface.
    public static let isAbstract = "isAbstract"

    // MARK: Ecore shortcuts

    /// The Ecore package of a generator package.
    public static let ecorePackage = "ecorePackage"
    /// The Ecore class of a generator class.
    public static let ecoreClass = "ecoreClass"
    /// The Ecore feature of a generator feature.
    public static let ecoreFeature = "ecoreFeature"
    /// The Ecore enumeration of a generator enumeration.
    public static let ecoreEnum = "ecoreEnum"
    /// The Ecore literal of a generator literal.
    public static let ecoreEnumLiteral = "ecoreEnumLiteral"
    /// The Ecore data type of a generator data type.
    public static let ecoreDataType = "ecoreDataType"
    /// Whether a feature is a reference.
    public static let isReferenceType = "isReferenceType"
    /// Whether a feature is an attribute.
    public static let isAttributeType = "isAttributeType"
    /// Whether a feature is a containment reference.
    public static let isContainment = "isContainment"
    /// Whether a feature is the container end of a containment.
    public static let isContainer = "isContainer"
    /// Whether a feature has an opposite.
    public static let isBidirectional = "isBidirectional"
    /// The generator feature of the opposite reference.
    public static let reverseGenFeature = "reverseGenFeature"
    /// Whether a feature holds several values.
    public static let isListType = "isListType"
    /// Whether a feature must have a value.
    public static let isRequired = "isRequired"
    /// Whether a feature can be modified.
    public static let isChangeable = "isChangeable"
    /// Whether a feature is volatile.
    public static let isVolatile = "isVolatile"
    /// Whether a feature is transient.
    public static let isTransient = "isTransient"
    /// Whether a feature is derived.
    public static let isDerived = "isDerived"
    /// Whether a feature can be unset.
    public static let isUnsettable = "isUnsettable"
    /// Whether references of a feature are resolved when proxies.
    public static let isResolveProxies = "isResolveProxies"
    /// Whether a feature has a default value literal.
    public static let hasDefault = "hasDefault"
    /// The default value literal of a feature.
    public static let defaultValueLiteral = "defaultValueLiteral"
    /// The lower bound of a feature.
    public static let lowerBound = "lowerBound"
    /// The upper bound of a feature.
    public static let upperBound = "upperBound"

    // MARK: Settings and documentation

    /// A setting of a generator element including its metamodel default.
    public static let setting = "setting"
    /// Whether a setting is explicitly set.
    public static let isSetting = "isSetting"
    /// The model documentation of an element.
    public static let documentation = "documentation"
    /// Whether an element has model documentation.
    public static let hasDocumentation = "hasDocumentation"
    /// The value of an annotation detail of an element.
    public static let annotationDetail = "annotationDetail"

    // MARK: Text helpers

    /// The lines of a text.
    public static let lines = "lines"
    /// The text with every line after the first prefixed.
    public static let indentLines = "indentLines"
    /// The UTF-16 code units of a text.
    public static let characterCodes = "characterCodes"
    /// The character that a UTF-16 code unit stands for.
    public static let fromCharacterCode = "fromCharacterCode"
    /// A number in hexadecimal notation.
    public static let toHexString = "toHexString"
    /// A number in octal notation.
    public static let toOctalString = "toOctalString"
    /// The elements of a collection joined into one text.
    public static let join = "join"
    /// The keys of the details of an annotation.
    public static let detailKeys = "detailKeys"
    /// The value of a detail of an annotation.
    public static let detailValue = "detailValue"

    // MARK: Template data

    /// The root objects of a data model bundled with a template set.
    public static let templateData = "templateData"
}
