//
// SwiftHenshinVocabulary.swift
// swift-henshin
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Henshin
import ModellingCommandLine

/// The names, markers and spellings that the swift-henshin tool relies on.
///
/// Every value that carries meaning for the command line, the files the tool reads and
/// writes, or the way it prints results is defined here once, so that the commands, their
/// help and their tests agree.
enum SwiftHenshinVocabulary {
    /// The name of the tool, as typed on the command line.
    static let toolName = "swift-henshin"

    /// The version that `--version` reports.
    static let version = "0.8.0"

    /// The names of the subcommands.
    enum Command {
        /// The subcommand that applies a unit or rule to a model.
        static let apply = "apply"

        /// The subcommand that checks a module.
        static let validate = "validate"

        /// The subcommand that translates JavaScript expressions into AQL.
        static let translate = "translate"

        /// The subcommand that finds conflicts and dependencies of rules.
        static let analyse = "analyse"

        /// The subcommand that explores the state space of a model.
        static let explore = "explore"

        /// The subcommand that converts modules between their document formats.
        static let convert = "convert"
    }

    /// The long names of the options.
    enum OptionName {
        /// The option that names the unit or rule to apply.
        static let unit = "unit"

        /// The option that gives a parameter value.
        static let param = "param"

        /// The option that names the file to write.
        static let output = "output"

        /// The option that seeds non-deterministic matching.
        static let seed = "seed"

        /// The flag that makes matching non-deterministic.
        static let nondeterministic = "nondeterministic"

        /// The flag that checks the dangling condition for every rule.
        static let checkDangling = MatchingOptionName.checkDangling

        /// The flag that turns the dangling condition off for every rule.
        static let noDanglingCheck = "no-dangling-check"

        /// A shorter spelling of ``noDanglingCheck``.
        static let noDangling = "no-dangling"

        /// The flag that makes matching injective for every rule.
        static let injective = MatchingOptionName.injective

        /// The flag that makes matching non-injective for every rule.
        static let nonInjective = "non-injective"

        /// The option that bounds the iterations of loop units.
        static let iterationLimit = "iteration-limit"

        /// The flag that reports every rule application.
        static let trace = "trace"

        /// The flag that applies without writing the model.
        static let dryRun = "dry-run"

        /// The flag that reports progress and details.
        static let verbose = "verbose"

        /// The option that gives the JavaScript expression to translate.
        static let expression = "expression"

        /// The option that declares the variables of an expression.
        static let variables = "variables"

        /// The flag that prints the translation table.
        static let table = "table"

        /// The option that selects rules.
        static let rules = "rules"

        /// The option that selects units.
        static let units = "units"

        /// The option that chooses conflicts, dependencies or both.
        static let direction = "direction"

        /// The option that chooses how finely interactions are described.
        static let granularity = "granularity"

        /// The flag that reports only essential critical pairs.
        static let essential = "essential"

        /// The flag that lets overlaps ignore metamodel multiplicities.
        static let noMultiplicities = "no-multiplicities"

        /// The option that chooses the output format of the analysis.
        static let format = "format"

        /// The option that bounds the number of states.
        static let maxStates = "max-states"

        /// The option that bounds the depth of states.
        static let maxDepth = "max-depth"

        /// The option that bounds the number of objects of a state.
        static let maxObjects = "max-objects"

        /// The option that chooses how states are identified.
        static let identity = "identity"

        /// The option that gives a reachability property.
        static let reach = "reach"

        /// The option that gives an invariant.
        static let invariant = "invariant"

        /// The option that names a forbidden pattern.
        static let forbid = "forbid"

        /// The flag that checks deadlock freedom.
        static let deadlock = "deadlock"

        /// The option that names the Graphviz file to write.
        static let dot = "dot"

        /// The option that sets the number of states expanded at once.
        static let workers = "workers"

        /// The flag that allows an existing file to be replaced.
        static let force = "force"
    }

    /// The names of the values of the options in the usage of a command.
    enum ValueName {
        /// The value of the module argument.
        static let module = "module.henshin"

        /// The value of the model argument.
        static let model = "model.xmi"

        /// The value of the output option.
        static let output = "file"

        /// The value of the unit option.
        static let unit = "name"

        /// The value of the parameter option of `apply`.
        static let param = "name=value"

        /// The value of the parameter option of `explore`.
        static let unitParam = "unit.name=value"

        /// The value of a numeric option.
        static let number = "n"

        /// The value of the expression of `translate`.
        static let expression = "expression"

        /// The value of the variables option.
        static let variables = "name,..."

        /// The value of the rules and units options.
        static let names = "name,..."

        /// The value of an AQL property.
        static let aql = "aql"

        /// The value of a pattern rule.
        static let rule = "rule"

        /// The value of the Graphviz output option.
        static let dot = "file.dot"

        /// The value of the granularity option.
        static let level = "level"

        /// The value of the direction option.
        static let direction = "direction"

        /// The value of the format option.
        static let format = "format"

        /// The value of the identity option.
        static let identity = "mode"
    }

    /// The file extensions of the documents that the tool reads and writes.
    enum FileExtension {
        /// The extension of Henshin documents in XMI.
        static let henshin = HenshinConstants.fileExtension

        /// The extension of Henshin Text documents.
        static let henshinText = HenshinTextConstants.fileExtension
    }

    /// The separators of values that the options take.
    enum Separator {
        /// The character that separates the names of a list option, such as `--rules a,b`.
        static let list: Character = ","

        /// The character that separates a unit from its parameter in `explore --param`.
        static let unitParameter: Character = "."

        /// The character that starts a fragment path that names an object, such as `//@bins.0`.
        static let fragment: Character = "/"
    }

    /// The words that `--param` reads as Boolean values.
    enum BooleanText {
        /// The text of the value `true`.
        static let `true` = "true"

        /// The text of the value `false`.
        static let `false` = "false"
    }

    /// The names of the parameter families in messages.
    enum Noun {
        /// The word for a parameter of a unit.
        static let parameter = "parameter"

        /// The placeholder for the name of a unit parameter in `explore`.
        static let unitParameter = "unit.name"
    }

    /// The parts of the text that the tool prints.
    enum Display {
        /// The text that opens the label of an object, as in `Bin(A)`.
        static let labelOpening = "("

        /// The text that closes the label of an object.
        static let labelClosing = ")"

        /// The name of the attribute that labels objects, compared ignoring case.
        static let labelAttributeName = "name"

        /// The text that separates a name from its value in a list of bindings.
        static let binding = "="

        /// The text that separates bindings in a list.
        static let bindingSeparator = ", "

        /// The text that separates a parameter name from its value in a printed line.
        static let parameterAssignment = " = "

        /// The text that stands for a value that is absent.
        static let null = "null"

        /// The text that stands for an object that no longer exists.
        static let deleted = "(deleted)"

        /// The text that starts the line of a warning.
        static let warningPrefix = ConversionWarningReport.warningPrefix

        /// The text that starts the line of an error.
        static let errorPrefix = FileDiagnosticReport.errorPrefix

        /// The text that starts the line of an informational finding.
        static let informationPrefix = "note: "

        /// The text that starts the line of a trace entry.
        static let tracePrefix = "applied "

        /// The text that starts a verbose line.
        static let verbosePrefix = "note: "

        /// The quote around text values.
        static let quote = "\""
    }

    /// The values of the output format option of `analyse`.
    enum OutputFormat: String, CaseIterable, Sendable {
        /// Readable text.
        case text
        /// A JSON document.
        case json
    }

    /// The values of the direction option of `analyse`.
    enum Direction: String, CaseIterable, Sendable {
        /// Conflicts only.
        case conflict
        /// Dependencies only.
        case dependency
        /// Conflicts, then dependencies.
        case both
    }

    /// The values of the granularity option of `analyse`, from coarse to fine.
    enum Granularity: String, CaseIterable, Sendable {
        /// Whether the rules interact at all.
        case binary
        /// The atoms of the interactions.
        case atoms
        /// The atoms and the minimal reasons.
        case minimalReasons = "minimal-reasons"
        /// The atoms, the minimal reasons and the critical pairs.
        case criticalPairs = "critical-pairs"
    }

    /// The values of the identity option of `explore`.
    enum StateIdentity: String, CaseIterable, Sendable {
        /// States are the same if their models are isomorphic.
        case isomorphism
        /// States are the same only if they have the same objects.
        case identity
    }

    /// The exit statuses that the tool documents.
    enum ExitStatus {
        /// The command did what was asked and every check passed.
        static let success: Int32 = 0

        /// The command could not do what was asked, or a module has errors.
        static let failure: Int32 = 1

        /// `apply`: the unit did not apply; `explore`: a property does not hold.
        static let negative: Int32 = 2

        /// `explore`: no property failed, but at least one result is inconclusive because the
        /// state space is incomplete.
        static let inconclusive: Int32 = 3
    }
}
