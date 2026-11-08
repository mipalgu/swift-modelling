//
// RunCommand.swift
// swift-xtend
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import ModellingCommandLine
import Xtend

/// The command that calls a method of an Xtend class on a model.
struct RunCommand: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftXtendVocabulary.Command.run,
        abstract: "Call a method of an Xtend class on a model",
        discussion: """
            Calls the method that --\(SwiftXtendVocabulary.OptionName.method) names on a new \
            instance of the class that --\(SwiftXtendVocabulary.OptionName.className) names, or \
            on the only class of the source, and prints the result on standard output. A method \
            that returns nothing prints nothing, and text written with print or println is \
            printed before the result.

            \(SwiftXtendCommand.bindingDiscussion)

            \(SwiftXtendCommand.outputDiscussion)

            Examples:
              swift-xtend run Report.xtend --model library.xmi --metamodel Library.ecore --method describe
              swift-xtend run Report.xtend --model library.xmi --method count --object "City Library"
              swift-xtend run Maths.xtend --method add --argument 2 --argument 3
              swift-xtend run Cleanup.xtend --model library.xmi --method retire --output cleaned.xmi

            \(SourceEncodingOptions.discussion(reader: "the Xtend source files"))

            \(SemanticsOptions.discussion())

            \(SwiftXtendCommand.statusDiscussion)
            """
    )

    /// The source, models, metamodels and class.
    @OptionGroup var programOptions: ProgramOptions

    /// The name of the method to call.
    @Option(
        name: [.customShort("n"), .customLong(SwiftXtendVocabulary.OptionName.method)],
        help: ArgumentHelp("The method to call", valueName: SwiftXtendVocabulary.ValueName.method))
    var method: String

    /// The literal arguments of the method.
    @Option(
        name: .customLong(SwiftXtendVocabulary.OptionName.argument),
        help: ArgumentHelp(
            "A text, number or Boolean argument of the method (can be specified multiple times)",
            valueName: SwiftXtendVocabulary.ValueName.argument))
    var arguments: [String] = []

    /// The name of the model object to pass to the method.
    @Option(
        name: .customLong(SwiftXtendVocabulary.OptionName.object),
        help: ArgumentHelp(
            "The name of the model object to pass for a parameter of a model class",
            valueName: SwiftXtendVocabulary.ValueName.object))
    var objectName: String?

    /// The file that receives the model after the method has run.
    @Option(
        name: [.customShort("o"), .customLong(SwiftXtendVocabulary.OptionName.output)],
        help: ArgumentHelp(
            "Write the model that the method changed or created to this file (format by extension)",
            valueName: SwiftXtendVocabulary.ValueName.outputModel))
    var output: String?

    /// Calls the method and prints its result.
    ///
    /// - Throws: ``SwiftXtendError`` if the program cannot be run or the call fails.
    @MainActor
    func run() async throws {
        do {
            let session = try await XtendSession.open(programOptions)
            let xtendClass = try session.selectClass(named: programOptions.className)
            let candidates = xtendClass.methods.filter { $0.name == method && !$0.isConstructor }
            guard !candidates.isEmpty else {
                let names = Array(Set(xtendClass.methods.filter { !$0.isConstructor }.map(\.name))).sorted()
                throw SwiftXtendError.methodNotFound(method, xtendClass.qualifiedName, names)
            }
            let binder = ArgumentBinder(models: session.models, literals: arguments, objectName: objectName)
            var values: [XtendHostValue]?
            var failure: (any Error)?
            for candidate in candidates {
                do {
                    values = try await binder.bind(candidate.parameters, method: method)
                    break
                } catch {
                    failure = failure ?? error
                }
            }
            guard let values else { throw failure ?? SwiftXtendError.argumentBinding(method, "no overload matches") }
            var target: Resource?
            if let output {
                target = await session.resourceSet.createResource(uri: URL(fileURLWithPath: output).absoluteString)
            }
            let interpreter = try XtendInterpreter(program: session.program, resources: session.models, targetResource: target)
            if programOptions.verbose { XtendSession.report("Calling \(xtendClass.qualifiedName).\(method)") }
            let result = try await interpreter.call(method, of: xtendClass.qualifiedName, arguments: values)
            let printed = await interpreter.standardOutput
            if !printed.isEmpty { print(printed, terminator: printed.hasSuffix("\n") ? "" : "\n") }
            if case .null = result {} else {
                print(await ResultFormatter(models: session.models).format(result))
            }
            if let output, let target {
                let created = await target.count() > 0
                let resource = created ? target : session.models.first
                guard let resource else {
                    throw SwiftXtendError.argumentBinding(method, "there is no model to write to \(output)")
                }
                if programOptions.verbose { XtendSession.report("Writing \(output)") }
                let url = URL(fileURLWithPath: output)
                try await ModelIO.save(resource, to: url, format: ModelFileFormat.instanceFormat(of: url))
            }
        } catch {
            throw SwiftXtendError.execution(error)
        }
    }
}
