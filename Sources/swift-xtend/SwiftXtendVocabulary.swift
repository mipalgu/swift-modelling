//
// SwiftXtendVocabulary.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Xtend

/// The names, markers and spellings that the swift-xtend tool relies on.
///
/// Every value that carries meaning for the command line, the way arguments are bound to the
/// parameters of a method or the way results are printed is defined here once, so that the
/// commands, their help and their tests agree.
enum SwiftXtendVocabulary {
    /// The name of the tool, as typed on the command line.
    static let toolName = "swift-xtend"

    /// The version that `--version` reports.
    static let version = "0.8.1"

    /// The names of the subcommands.
    enum Command {
        /// The subcommand that calls a method of a class on a model.
        static let run = "run"

        /// The subcommand that runs a generator over a model.
        static let generate = "generate"
    }

    /// The long names of the options.
    enum OptionName {
        /// The option that names a model to load.
        static let model = "model"

        /// The option that names an additional Xtend source file.
        static let include = "include"

        /// The option that names the class to use.
        static let className = "class"

        /// The option that names the method to call.
        static let method = "method"

        /// The option that gives a literal argument of the method.
        static let argument = "argument"

        /// The option that selects the model object passed to a parameter.
        static let object = "object"

        /// The option that names the output of the command.
        static let output = "output"

        /// The option that maps a named output configuration to a directory.
        static let outputConfiguration = "output-configuration"

        /// The flag that reports progress.
        static let verbose = "verbose"

        /// The flag that suppresses the report of the files written.
        static let quiet = "quiet"
    }

    /// The names of the values of the options in the usage of a command.
    enum ValueName {
        /// The value of an option that names a model file.
        static let model = "file"

        /// The argument that names the Xtend source file.
        static let source = "file.xtend"

        /// The value of an option that names a class.
        static let className = "class"

        /// The value of an option that names a method.
        static let method = "method"

        /// The value of an option that gives an argument.
        static let argument = "value"

        /// The value of an option that selects a model object.
        static let object = "name"

        /// The value of the output option of `run`.
        static let outputModel = "file"

        /// The value of the output option of `generate`.
        static let outputDirectory = "directory"

        /// The key of the output configuration option, followed by the directory.
        static let outputConfiguration = "name=directory"
    }

    /// The noun that names an output configuration in messages.
    static let outputConfigurationNoun = "output configuration"

    /// The file extension of Xtend source files.
    static let sourceExtension = XtendLanguage.fileExtension

    /// The name of the attribute that labels an object whenever its class has one, ignoring case.
    static let labelAttributeName = "name"

    /// The names of the Ecore data types that hold text.
    static let stringTypeNames: Set<String> = ["EString", "String"]

    /// The spellings with which results are printed.
    enum Display {
        /// The text that opens a collection.
        static let collectionOpening = "["

        /// The text that closes a collection.
        static let collectionClosing = "]"

        /// The text that separates the elements of a collection.
        static let separator = ", "

        /// The text that opens the label of an object after its class name.
        static let labelOpening = "("

        /// The text that closes the label of an object.
        static let labelClosing = ")"

        /// The text that opens a map.
        static let mapOpening = "{"

        /// The text that closes a map.
        static let mapClosing = "}"

        /// The text between the key and the value of a map entry or pair.
        static let association = "="

        /// The text that separates the name of an output configuration from a path.
        static let configurationSeparator = ":"
    }

    /// The names of types by which arguments are bound to the parameters of a method.
    enum ParameterType {
        /// Types that stand for a whole model resource.
        static let resources: Set<String> = ["Resource"]

        /// Types that accept any model object.
        static let anyObject: Set<String> = ["EObject", "Object"]

        /// Types that accept a file system access, which only generators can be given.
        static let fileSystems: Set<String> = ["IFileSystemAccess", "IFileSystemAccess2", "IGeneratorContext"]

        /// Types of text values.
        static let strings: Set<String> = ["String", "CharSequence"]

        /// Types of whole number values.
        static let integers: Set<String> = [
            "int", "Integer", "long", "Long", "short", "Short", "byte", "Byte", "BigInteger",
        ]

        /// Types of floating point values.
        static let doubles: Set<String> = ["double", "Double", "float", "Float", "BigDecimal"]

        /// Types of truth values.
        static let booleans: Set<String> = ["boolean", "Boolean"]

        /// Types of collections of model objects.
        static let collections: Set<String> = ["List", "Collection", "Iterable", "Set", "EList"]
    }

    /// The spellings of the truth values that an argument can take.
    enum BooleanText {
        /// The spelling of true.
        static let yes = "true"

        /// The spelling of false.
        static let no = "false"
    }
}
