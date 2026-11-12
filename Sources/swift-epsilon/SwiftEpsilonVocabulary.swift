//
// SwiftEpsilonVocabulary.swift
// swift-epsilon
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EGL
import ModellingCommandLine

/// The names, markers and spellings that the swift-epsilon tool relies on.
///
/// Every value that carries meaning for the command line, the models it binds, the files it
/// reads and writes or the way it reports results is defined here once, so that the commands,
/// their help and their tests agree.
enum SwiftEpsilonVocabulary {
    /// The name of the tool, as typed on the command line.
    static let toolName = "swift-epsilon"

    /// The version that `--version` reports.
    static let version = "0.8.1"

    /// The names of the command groups, one for each Epsilon language.
    enum Group {
        /// The group of the Epsilon Object Language.
        static let eol = "eol"

        /// The group of the Epsilon Validation Language.
        static let evl = "evl"

        /// The group of the Epsilon Transformation Language.
        static let etl = "etl"

        /// The group of the Epsilon Generation Language and its coordination language EGX.
        static let egl = "egl"
    }

    /// The names of the subcommands within their groups.
    enum Command {
        /// The subcommand that runs an EOL program.
        static let run = "run"

        /// The subcommand that checks models against EVL constraints.
        static let validate = "validate"

        /// The subcommand that runs an ETL transformation.
        static let transform = "transform"

        /// The subcommand that renders an EGL template or runs an EGX coordination module.
        static let generate = "generate"
    }

    /// The long names of the options.
    enum OptionName {
        /// The option that binds a model that is read from a file.
        static let model = "model"

        /// The option that binds a model that is created empty and stored in a file.
        static let target = "target"

        /// The option that stores a model given with `--model` after the run.
        static let store = "store"

        /// The option that passes a parameter to the program as a global variable.
        static let parameter = "param"

        /// The option that limits the depth of nested operation calls.
        static let maximumCallDepth = "max-call-depth"

        /// The flag that reports progress in detail on standard error.
        static let verbose = "verbose"

        /// The flag that applies the fixes of unsatisfied constraints.
        static let fix = "fix"

        /// The flag that makes unsatisfied critiques fail validation as well.
        static let strict = ValidationOptionName.strict

        /// The flag that prints the trace of a transformation.
        static let trace = "trace"

        /// The option that names the output file of a template or the directory of EGX rules.
        static let output = "output"

        /// The flag that replaces an existing file instead of keeping its protected regions.
        static let noMerge = "no-merge"

        /// The flag that lets EGX rules write files outside the output directory.
        static let allowOutsideOutput = "allow-outside-output"
    }

    /// The names of the values of the options in the usage of a command.
    enum ValueName {
        /// The value of an option that binds a model to a file.
        static let model = "name=file"

        /// The value of `--store`.
        static let store = "name[=file]"

        /// The value of `--param`.
        static let parameter = "name=value"

        /// The value of `--max-call-depth`.
        static let maximumCallDepth = "depth"

        /// The value of `--output`.
        static let output = "path"

        /// The program argument of `eol run`.
        static let program = "program.eol"

        /// The constraints argument of `evl validate`.
        static let constraints = "constraints.evl"

        /// The transformation argument of `etl transform`.
        static let transformation = "transformation.etl"

        /// The template argument of `egl generate`.
        static let template = "template.egl|rules.egx"
    }

    /// The nouns with which the families of `name=value` options are named in messages.
    enum Noun {
        /// The noun of `--model` and `--target`.
        static let model = "model"

        /// The noun of `--store`.
        static let store = "stored model"

        /// The noun of `--param`.
        static let parameter = "parameter"
    }

    /// The syntax of the values of the model options.
    enum Binding {
        /// The character that separates the name of a model from its aliases.
        static let aliasSeparator: Character = ","
    }

    /// The spellings with which parameter values are typed.
    enum ParameterLiteral {
        /// The text of the Boolean true.
        static let trueText = "true"

        /// The text of the Boolean false.
        static let falseText = "false"
    }

    /// The file extensions that the tool distinguishes.
    enum FileExtension {
        /// The extension of an EGX coordination module.
        static let coordination = "egx"
    }

    /// The exit statuses that the commands document beyond success.
    enum ExitStatus {
        /// The status of `evl validate` when a constraint, or with `--strict` a critique, is
        /// unsatisfied.
        static let unsatisfied: Int32 = 2
    }

    /// The default limit of nested operation calls, which is that of the interpreter.
    static let defaultMaximumCallDepth = 1_000

    /// The texts with which validation results are reported.
    enum Validation {
        /// The word that introduces an unsatisfied constraint, which is an error.
        static let constraint = "constraint"

        /// The word that introduces an unsatisfied critique, which is a warning.
        static let critique = "critique"

        /// The text that starts the line of an error.
        static let errorPrefix = "error: "

        /// The text that starts the line of a warning.
        static let warningPrefix = "warning: "

        /// The text that starts the line of a fix that is offered.
        static let fixPrefix = "  fix: "

        /// The text that starts the line of a fix that was applied.
        static let appliedPrefix = "applied: "

        /// The word between the name of a constraint and the element it concerns.
        static let elementSeparator = " on "

        /// The text between the element and the message.
        static let messageSeparator = ": "

        /// The noun that counts unsatisfied constraints in the summary.
        static let errorNoun = "error"

        /// The noun that counts unsatisfied critiques in the summary.
        static let warningNoun = "warning"

        /// The suffix of a noun in the plural.
        static let pluralSuffix = "s"

        /// The text between the counts of the summary.
        static let countSeparator = ", "

        /// The line printed when every constraint and critique is satisfied.
        static let allSatisfied = "All constraints are satisfied"
    }

    /// The directory into which EGX rules write when `--output` is not given.
    static let defaultOutputDirectory = "."

    /// The texts with which a transformation trace is printed.
    enum Trace {
        /// The text between the rule and the source element.
        static let ruleSeparator = ": "

        /// The text between the source element and its targets.
        static let arrow = " -> "

        /// The text between targets.
        static let targetSeparator = ", "
    }

    /// The words with which the status of a generated file is reported.
    enum FileStatus {
        /// The text between the status and the path of a file.
        static let separator = ": "

        /// The word for a file that rules generated but did not write.
        static let notWritten = "not written"

        /// The word for a status.
        ///
        /// - Parameter status: The status of a generated file.
        /// - Returns: The word with which the status is printed, such as `created`.
        static func word(for status: EGXFileStatus) -> String {
            status == .notWritten ? notWritten : status.rawValue
        }
    }

    /// The messages of the activity indicator and of verbose output.
    enum Activity {
        /// The activity while an EOL program runs.
        static let running = "Running"

        /// The activity while models are validated.
        static let validating = "Validating"

        /// The activity while a transformation runs.
        static let transforming = "Transforming"

        /// The activity while files are generated.
        static let generating = "Generating"

        /// The text after an activity.
        static let ellipsis = "..."
    }
}
