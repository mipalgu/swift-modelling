//
// SwiftHenshin.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The main command-line interface for Swift Henshin.
///
/// Swift Henshin applies Henshin graph transformation rules and units to models, checks
/// modules, translates the JavaScript of their expressions into AQL, analyses the conflicts
/// and dependencies of rules, explores the state spaces that rules span, and converts modules
/// into Henshin Text.
///
/// ## Available Commands
///
/// - **apply**: apply a unit or rule to a model
/// - **validate**: check a module, including Henshin's clean-up checks
/// - **translate**: translate a JavaScript expression into AQL, or print the translation table
/// - **analyse**: find the conflicts and dependencies of rules
/// - **explore**: explore the state space of a model and check properties
/// - **convert**: write a module as Henshin Text
///
/// ## Example Usage
///
/// ```bash
/// swift-henshin apply depot.henshin depot.xmi --unit addParcel --param binName=A -o out.xmi
/// swift-henshin explore depot.henshin depot.xmi --rules move --deadlock
/// ```
@main
struct SwiftHenshinCommand: AsyncParsableCommand {
    /// The name, summary, version and subcommands of the tool.
    static let configuration = CommandConfiguration(
        commandName: SwiftHenshinVocabulary.toolName,
        abstract: "Henshin graph transformation command-line tool",
        discussion: """
            Copyright (c) 2026 Rene Hexel.
            All rights reserved.

            Swift Henshin applies the rules and units of Henshin modules (.henshin documents \
            in XMI, or .henshin_text documents in Henshin Text) to models in XMI or JSON, \
            checks modules, analyses the conflicts and dependencies of rules, and explores the \
            states that rules reach from a model.

            Exit statuses: 0 on success, 1 if the command fails or a module has errors, 2 if \
            apply cannot apply its unit or explore finds that a property does not hold, 3 if \
            explore finds no violation but cannot conclude because the state space is \
            incomplete, and 64 for an invalid command line.
            """,
        version: SwiftHenshinVocabulary.version,
        subcommands: [
            ApplyCommand.self,
            ValidateCommand.self,
            TranslateCommand.self,
            AnalyseCommand.self,
            ExploreCommand.self,
            ConvertCommand.self,
        ]
    )

    /// A paragraph that describes how the metamodels of a module are found.
    static let metamodelDiscussion = """
        --\(MetamodelOptions.optionName) registers a metamodel before the module is read. \
        Without it, a .henshin document finds its metamodels at the locations it names, and \
        a .henshin_text document finds the packages that ePackageImport names among the Ecore \
        documents beside it. Models are read with the same metamodels, so that their \
        classes are those of the rules.
        """

    /// A paragraph that describes the encoding of Henshin Text documents.
    static let encodingDiscussion = SourceEncodingOptions.discussion(
        reader: "a .henshin_text module", configurable: false)

    /// A paragraph that describes how parameter values are typed.
    static let parameterDiscussion = """
        A value is converted to the declared type of its parameter: an integer for EInt, \
        ELong, EShort or EByte, a real number for EDouble or EFloat, true or false for \
        EBoolean, and the text as given for EString. A parameter whose type is a class names \
        an object of the model by the value of its name attribute (or its first text \
        attribute) or by a fragment path such as //@bins.0. An untyped parameter takes an \
        integer, a real number or a Boolean value if the text reads as one, and the text \
        otherwise.
        """

    /// A paragraph that describes the options that override matching.
    static let matchingDiscussion = """
        --check-dangling and --no-dangling-check (or --no-dangling) override the dangling \
        condition of every rule: with it, a rule does not apply where deleting its objects \
        would leave a reference dangling; without it, such references are removed. \
        --injective and --non-injective override whether different nodes of a rule must \
        match different objects. Without them, every rule keeps its own settings.
        """
}
