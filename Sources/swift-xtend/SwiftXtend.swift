//
// SwiftXtend.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingCommandLine

/// The main command-line interface for Swift Xtend.
///
/// Swift Xtend interprets a documented subset of Eclipse Xtend over models, without a Java
/// virtual machine, so that code generators and model queries or changes written in Xtend can
/// be run from scripts.
///
/// ## Available Commands
///
/// - **run**: call a method of an Xtend class on a model and print its result
/// - **generate**: run an Xtend generator over a model and write the files it generates
///
/// ## Example Usage
///
/// ```bash
/// swift-xtend run Report.xtend --model library.xmi --method describe
/// swift-xtend generate Catalogue.xtend --model library.xmi --output generated
/// ```
@main
struct SwiftXtendCommand: AsyncParsableCommand {
    /// The name, summary, version and subcommands of the tool.
    static let configuration = CommandConfiguration(
        commandName: SwiftXtendVocabulary.toolName,
        abstract: "Xtend command-line tool",
        discussion: """
            Copyright (c) 2026 Rene Hexel.
            All rights reserved.

            Swift Xtend interprets a documented subset of Eclipse Xtend, including rich strings, \
            dispatch and create methods, over models in XMI, JSON or UML format and their Ecore \
            metamodels, without a Java virtual machine.
            """,
        version: SwiftXtendVocabulary.version,
        subcommands: [
            RunCommand.self,
            GenerateCommand.self,
        ]
    )

    /// A paragraph that describes how arguments reach the method.
    static let bindingDiscussion = """
        The parameters of the method take their values from their types. A Resource is the \
        first model. A class of the metamodel, or EObject, is its first instance in the models, \
        or the instance whose name --\(SwiftXtendVocabulary.OptionName.object) gives. A list of \
        such a class holds all its instances. The cases of a dispatch method share one \
        dispatcher, as in Xtend, whose parameter types are the common supertypes of those of \
        the cases, so that a parameter of a dispatch method is the first instance of that \
        common type unless --\(SwiftXtendVocabulary.OptionName.object) names one. A String, \
        number or Boolean takes the next \
        --\(SwiftXtendVocabulary.OptionName.argument) value. With --\(SwiftXtendVocabulary.OptionName.output), \
        the model that the method created with new is written to the file, in the format its \
        extension names, or else the first model after the method has changed it.
        """

    /// A paragraph that describes how the result is printed.
    static let outputDiscussion = """
        Text and numbers are printed as they are, model objects as their class name followed by \
        their name in parentheses, such as Book(Dune), lists in square brackets and maps in braces.
        """

    /// A paragraph that describes the exit statuses.
    static let statusDiscussion = """
        Exit status: 0 on success, 1 if a file cannot be read, the source has errors or the \
        program fails, and 64 if the command line is invalid. Warnings and progress are \
        written to standard error.
        """
}
