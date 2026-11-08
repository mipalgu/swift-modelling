//
// ApplyCommand.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import EMFBase
import Henshin
import ModellingCommandLine

/// The command that applies a unit or rule of a module to a model.
///
/// The unit is applied with Henshin's semantics. The transformed model is written to the file
/// that `--output` names, in the format of its extension, or else printed on standard output
/// in the format in which it was read; the model file itself is never changed. A unit that
/// does not apply leaves nothing written and ends the command with status 2.
struct ApplyCommand: AsyncParsableCommand {
    /// Shorthand for the option names.
    private typealias Key = SwiftHenshinVocabulary.OptionName
    /// Shorthand for the value names.
    private typealias Placeholder = SwiftHenshinVocabulary.ValueName

    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: SwiftHenshinVocabulary.Command.apply,
        abstract: "Apply a unit or rule of a module to a model",
        discussion: """
            Applies the unit or rule that --\(Key.unit) names to the model, with the values \
            that --\(Key.param) gives for its parameters, repeated once per parameter. \
            \(SwiftHenshinCommand.parameterDiscussion)

            The transformed model is written to the file that --\(Key.output) names, in \
            the format that its extension names (XMI unless it is .json or .uml); without \
            --\(Key.output) it is printed on standard output in the format in which it was \
            read. The model file itself is not changed. --\(Key.dryRun) applies the unit \
            without writing or printing the model. The parameter values that the unit reports \
            (for a rule, every parameter but its variables; for other units, the output and \
            input-output parameters) are printed as name = value lines, on standard output, or \
            on standard error while the model is printed on standard output.

            Matching is deterministic, as in Henshin. --\(Key.nondeterministic) shuffles \
            the candidates of matches and the sub-units of independent units, and \
            --\(Key.seed) makes that choice reproducible. --\(Key.iterationLimit) stops \
            loop units after a number of iterations, with a warning. --\(Key.trace) lists \
            every rule application, with its match, on standard error.

            \(SwiftHenshinCommand.matchingDiscussion)

            \(SwiftHenshinCommand.metamodelDiscussion)

            \(SwiftHenshinCommand.encodingDiscussion)

            Exit statuses: 0 if the unit applied, 2 if it did not (nothing is written), 1 for \
            any other error, such as a missing parameter or an expression that cannot be \
            evaluated (the model is then left as it was), and 64 for an invalid command line.

            Examples:
              swift-henshin apply depot.henshin depot.xmi -u addParcel \\
                --param binName=A --param code=P3 --param weight=4 -o depot-out.xmi
              swift-henshin apply depot.henshin_text depot.xmi -u move --trace --dry-run
              swift-henshin apply depot.henshin depot.xmi -u spin --iteration-limit 10 \\
                -o depot-out.xmi
            """
    )

    /// The module file.
    @Argument(help: ArgumentHelp("The module (.henshin or .henshin_text)", valueName: Placeholder.module))
    var module: String

    /// The model file.
    @Argument(help: ArgumentHelp("The model to transform", valueName: Placeholder.model))
    var model: String

    /// The name of the unit or rule to apply.
    @Option(
        name: [.customShort("u"), .customLong(Key.unit)],
        help: ArgumentHelp("The unit or rule to apply", valueName: Placeholder.unit))
    var unit: String

    /// The parameter values, as `name=value` pairs.
    @Option(
        name: .customLong(Key.param),
        help: ArgumentHelp(
            "A value for a parameter of the unit (can be specified multiple times)", valueName: Placeholder.param))
    var param: [String] = []

    /// The file to write the transformed model to.
    @Option(
        name: [.customShort("o"), .customLong(Key.output)],
        help: ArgumentHelp(
            "The file to write the transformed model to (default: standard output)", valueName: Placeholder.output))
    var output: String?

    /// The seed of non-deterministic matching.
    @Option(
        name: .customLong(Key.seed),
        help: ArgumentHelp("Match non-deterministically, seeded for reproducible choices", valueName: Placeholder.number))
    var seed: UInt64?

    /// Whether matching is non-deterministic.
    @Flag(
        name: .customLong(Key.nondeterministic),
        help: "Choose matches and sub-units of independent units at random")
    var nondeterministic = false

    /// The largest number of iterations of a loop unit.
    @Option(
        name: .customLong(Key.iterationLimit),
        help: ArgumentHelp("Stop loop units after this many iterations", valueName: Placeholder.number))
    var iterationLimit: Int?

    /// Whether every rule application is reported.
    @Flag(name: .customLong(Key.trace), help: "List every rule application and its match on standard error")
    var trace = false

    /// Whether the model is left unwritten.
    @Flag(name: .customLong(Key.dryRun), help: "Apply the unit without writing or printing the model")
    var dryRun = false

    /// The overrides of matching.
    @OptionGroup(title: "Matching")
    var matchingOptions: MatchingOptions

    /// The options with which the module is read.
    @OptionGroup var moduleOptions: ModuleOptions

    /// Checks the combination of options.
    ///
    /// - Throws: A validation error if the iteration limit is not positive, or
    ///   `--dry-run` is given with `--output`.
    func validate() throws {
        if let iterationLimit, iterationLimit < 1 {
            throw ValidationError("--\(Key.iterationLimit) must be at least 1")
        }
        if dryRun && output != nil {
            throw ValidationError("--\(Key.dryRun) cannot be combined with --\(Key.output)")
        }
    }

    /// The engine options that the command line asks for.
    var engineOptions: EngineOptions {
        matchingOptions.engineOptions(
            EngineOptions(
                deterministic: !(nondeterministic || seed != nil), randomSeed: seed, iterationLimit: iterationLimit))
    }

    /// Applies the unit and writes the result.
    ///
    /// - Throws: `ExitCode` 2 if the unit does not apply, ``SwiftHenshinError`` and
    ///   `HenshinError` for other failures.
    @MainActor
    func run() async throws {
        let loader = moduleOptions.loader
        let log = loader.log
        let loaded = try await loader.load(module)
        let transformationUnit = try loaded.unit(named: unit)
        let arguments = try ParameterArguments.family(for: transformationUnit.parameters, classNames: loaded.classNames)
            .values(from: param)
        let target = try await ModelFile.load(model, into: loaded.resourceSet, log: log)
        let values = try await ParameterArguments.values(
            arguments, parameters: transformationUnit.parameters, in: target.resource)
        log.progress("applying \(unit)")
        let result = try await HenshinEngine(options: engineOptions).apply(
            unit: transformationUnit.id, of: loaded.module, to: target.resource, parameters: values)
        log.report(result.diagnostics, file: module)
        let formatter = await ValueFormatter.current(target.resource)
        if trace {
            for application in result.appliedRules {
                log.line(Self.traceLine(application, module: loaded.module, formatter: formatter))
            }
        }
        guard result.succeeded else {
            log.error("the unit '\(unit)' could not be applied to \(model); nothing was written")
            throw ExitCode(SwiftHenshinVocabulary.ExitStatus.negative)
        }
        log.progress("applied \(result.appliedRules.count) rule application(s)")
        let parameterLines = Self.parameterLines(result.parameters, formatter: formatter)
        if dryRun {
            parameterLines.forEach { print($0) }
        } else if let output {
            try await ModelFile.save(target.resource, to: output)
            log.progress("wrote \(output)")
            parameterLines.forEach { print($0) }
        } else {
            let text = try await ModelFile.text(of: target)
            print(text, terminator: text.hasSuffix("\n") ? "" : "\n")
            parameterLines.forEach(log.line)
        }
    }

    /// The line that reports a rule application.
    ///
    /// - Parameters:
    ///   - application: The application.
    ///   - module: The module that holds the rule.
    ///   - formatter: The formatter of the objects of the transformed model.
    /// - Returns: A line such as `applied move(source=Bin(A), target=Bin(B), m=0, n=2):
    ///   created 0, deleted 0`, with the matched objects in the order of the left-hand side
    ///   followed by the parameter values in the order of their names.
    static func traceLine(_ application: RuleApplication, module: HenshinModule, formatter: ValueFormatter) -> String {
        typealias Display = SwiftHenshinVocabulary.Display
        let nodes = module.unit(named: application.ruleName)?.rule?.lhs.nodes ?? []
        var bindings: [String] = []
        var nodeNames = Set<String>()
        for node in nodes {
            guard let object = application.match[node.id] else { continue }
            let name = node.name ?? node.id.description
            nodeNames.insert(name)
            let text = formatter.resolve(object).map(ValueFormatter.describe) ?? node.type.name + " " + Display.deleted
            bindings.append(name + Display.binding + text)
        }
        bindings += formatter.bindings(application.parameters.filter { !nodeNames.contains($0.key) })
        return Display.tracePrefix + application.ruleName + "(" + bindings.joined(separator: Display.bindingSeparator)
            + "): created \(application.createdObjects.count), deleted \(application.deletedObjects.count)"
    }

    /// The lines that report the values of output parameters.
    ///
    /// - Parameters:
    ///   - values: The values by parameter name.
    ///   - formatter: The formatter of the objects of the transformed model.
    /// - Returns: One `name = value` line per parameter, in the order of their names.
    static func parameterLines(_ values: ParameterValues, formatter: ValueFormatter) -> [String] {
        values.keys.sorted().map { $0 + SwiftHenshinVocabulary.Display.parameterAssignment + formatter.format(values[$0]) }
    }
}
