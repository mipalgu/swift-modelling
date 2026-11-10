//
// TutorialReplayConfiguration.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// The names, markers and limits that the replay of the tutorials and the check of the documented
/// command lines rely on.
///
/// Every value that carries meaning for the harness is defined here once, so that a change to the
/// conventions of the documentation catalogue, such as a new tool or another output marker, needs a
/// change in one place only.
enum TutorialReplayConfiguration {
    // MARK: - Tools

    /// The command-line tools whose invocations the tutorials and articles document.
    ///
    /// The replay puts the build products directory first on the search path, so these names
    /// resolve to the executables of this build. A tool that this package does not build yet, such
    /// as `swift-aql`, is then reported as a missing command rather than taken from elsewhere.
    static let toolNames = [
        "swift-ecore", "swift-atl", "swift-mtl", "swift-aql", "swift-henshin", "swift-epsilon", "swift-xtend",
    ]

    /// The subcommand that the argument parser of every tool with subcommands provides implicitly.
    static let implicitHelpSubcommand = "help"

    /// The option that prints the help of a tool or subcommand.
    static let helpOption = "--help"

    /// The marker that follows a subcommand in a help page when the subcommand is the default one.
    static let defaultSubcommandMarker = "(default)"

    /// The heading of the section of a help page that lists the subcommands.
    static let subcommandsHeading = "SUBCOMMANDS:"

    /// The command that runs an executable of a package, as in `swift run swift-ecore`.
    static let packageRunCommand = ["swift", "run"]

    // MARK: - Documentation catalogue

    /// The documentation catalogue that holds the tutorials, relative to the repository root.
    static let tutorialCatalogue = "Sources/SwiftModelling/SwiftModelling.docc"

    /// The directory of the catalogue that holds the tutorial files.
    static let tutorialsDirectory = "Tutorials"

    /// The directory of the catalogue that holds the resources the tutorials refer to.
    static let resourcesDirectory = "Resources"

    /// The directory of the repository that holds the source targets and their catalogues.
    static let sourcesDirectory = "Sources"

    /// The read-me file of the repository, whose command lines are checked.
    static let readMeFile = "README.md"

    /// The extension of a documentation catalogue directory.
    static let catalogueExtension = "docc"

    /// The extension of a tutorial file.
    static let tutorialExtension = "tutorial"

    /// The extension of an article file.
    static let articleExtension = "md"

    /// The directive that shows a code file in a tutorial step.
    static let codeDirective = "@Code"

    /// The argument of the code directive that names the file the reader sees.
    static let codeNameArgument = "name"

    /// The argument of the code directive that names the resource to show.
    static let codeFileArgument = "file"

    /// The argument of the code directive that names the resource of the previous version.
    static let codePreviousFileArgument = "previousFile"

    /// The directive that lists the tutorials of the table of contents.
    static let tableOfContentsDirective = "@Tutorials"

    /// The directive that refers to a tutorial from the table of contents.
    static let tutorialReferenceDirective = "@TutorialReference"

    /// The argument of the tutorial reference that names the tutorial.
    static let tutorialReferenceArgument = "tutorial"

    /// The scheme that prefixes a documentation link.
    static let documentationLinkScheme = "doc:"

    // MARK: - Resource usage

    /// The directives through which a tutorial or article of the catalogue uses a resource.
    static let resourceDirectives = ["@Code", "@Image", "@Video"]

    /// The arguments of ``resourceDirectives`` that name a resource.
    static let resourceArguments = ["file", "previousFile", "source", "poster"]

    /// The marker that DocC adds to the name of a resource for the dark appearance, as in `chart~dark.svg`.
    static let appearanceVariantMarkers = ["~dark"]

    /// The markers that DocC adds to the name of a resource for a display scale, as in `chart@2x.png`.
    static let scaleVariantMarkers = ["@1x", "@2x", "@3x"]

    /// The extensions of image resources whose Graphviz source sits beside them.
    static let imageExtensions: Set<String> = ["svg", "png", "jpg", "jpeg", "gif"]

    /// The extension of a Graphviz source, which counts as used when an image of the same stem is used.
    static let graphvizSourceExtension = "dot"

    /// Resources that count as used although nothing refers to them, by path relative to the
    /// resources directory, each with the reason.
    ///
    /// The rules of ``TutorialResourceUsage`` cover every kind of use that the catalogue has, so
    /// the list is empty. An entry belongs here only when a resource is used in a way that the
    /// rules cannot see, and its reason must say how.
    static let unusedResourceExceptions: [String: String] = [:]

    /// The name that a code directive gives to a shell script that the reader runs.
    static let terminalCodeName = "Terminal"

    /// The name that a code directive gives to text that a command printed.
    ///
    /// Such text is shown to the reader, not saved, so the replay writes no file for it.
    static let outputCodeName = "Output"

    // MARK: - Documented output

    /// The word that starts a comment block documenting the output of the commands above it.
    ///
    /// A script documents output as `# Output: text` on one line, or as `# Output:` followed by
    /// comment lines, optionally with a qualifier in parentheses such as `# Output (sample):`.
    static let outputMarker = "Output"

    /// The character that starts a shell comment.
    static let commentCharacter: Character = "#"

    /// The texts that stand for omitted output, as a line of their own or within a line.
    static let elisionMarkers = ["...", "…"]

    /// The placeholder that replaces the working directory of the replay in an output.
    static let workingDirectoryPlaceholder = "<workdir>"

    /// The placeholder that replaces a universally unique identifier.
    static let uuidPlaceholder = "<uuid>"

    // MARK: - Commands that the scripts need

    /// The builtins of bash, which a script needs no installed command for.
    static let shellBuiltins: Set<String> = [
        ".", ":", "[", "alias", "bg", "bind", "break", "builtin", "caller", "cd", "command", "compgen",
        "complete", "compopt", "continue", "declare", "dirs", "disown", "echo", "enable", "eval", "exec",
        "exit", "export", "false", "fc", "fg", "getopts", "hash", "help", "history", "jobs", "kill", "let",
        "local", "logout", "mapfile", "popd", "printf", "pushd", "pwd", "read", "readarray", "readonly",
        "return", "set", "shift", "shopt", "source", "suspend", "test", "times", "trap", "true", "type",
        "typeset", "ulimit", "umask", "unalias", "unset", "wait",
    ]

    /// The reserved words of bash, which are not commands.
    static let shellReservedWords: Set<String> = [
        "!", "{", "}", "[[", "]]", "case", "do", "done", "elif", "else", "esac", "fi", "for", "function", "if",
        "in", "select", "then", "time", "until", "while",
    ]

    /// The commands that run the command given as their first operand, such as `xargs grep`.
    static let commandWrappers: Set<String> = [
        "command", "env", "exec", "nice", "nohup", "stdbuf", "sudo", "time", "timeout", "xargs",
    ]

    /// The options of ``commandWrappers`` that take a value, so that the value is not taken for the command.
    static let commandWrapperOptionsWithValue: Set<String> = [
        "-I", "-L", "-P", "-d", "-n", "-s", "-E", "-u", "-k",
    ]

    /// The number of operands of a wrapper that precede the command, such as the duration of `timeout`.
    static let commandWrapperLeadingOperands: [String: Int] = ["timeout": 1]

    /// The options of `command` that only look a command up instead of running it.
    static let commandLookupOptions: Set<String> = ["-v", "-V"]

    /// The command whose options run another command, and those options.
    static let findCommand = "find"

    /// The options of ``findCommand`` that run the command after them.
    static let findExecutionOptions: Set<String> = ["-exec", "-execdir", "-ok", "-okdir"]

    /// The commands that POSIX specifies, or that the core, find, diff, grep, sed and awk utilities of
    /// every common Linux distribution and of macOS provide, so that even a minimal image has them.
    static let baselineCommands: Set<String> = [
        "awk", "basename", "cat", "chmod", "cksum", "cmp", "comm", "cp", "cut", "date", "dd", "df", "diff",
        "dirname", "du", "env", "expr", "find", "fold", "grep", "head", "id", "join", "ln", "ls", "mkdir",
        "mktemp", "mv", "nl", "od", "paste", "rm", "rmdir", "sed", "sleep", "sort", "split", "stat", "tail",
        "tee", "touch", "tr", "tty", "uname", "uniq", "wc", "xargs", "yes", "realpath", "readlink", "seq",
        "timeout", "nohup", "nice", "tar", "gzip",
    ]

    /// The commands whose name, options or output differ between macOS and Linux, with how they differ.
    static let platformDependentCommands: [String: String] = [
        "shasum": "part of Perl on macOS; Linux images often have only sha256sum",
        "sha256sum": "standard on Linux; missing from older macOS releases, which have shasum -a 256",
        "md5": "macOS only; Linux has md5sum",
        "md5sum": "Linux; macOS has md5",
        "sed": "sed -i needs a suffix argument on macOS (sed -i '') but not on Linux",
        "stat": "options differ: stat -f on macOS, stat -c on Linux",
        "date": "date -d on Linux, date -v or -j on macOS",
        "readlink": "readlink -f is missing from older macOS releases",
        "base64": "decoding is -d on Linux, -D on older macOS releases",
        "open": "macOS only; Linux uses xdg-open",
        "xargs": "xargs -r is a GNU extension",
        "find": "-printf and -regextype are GNU extensions",
        "grep": "grep -P is a GNU extension",
        "tar": "GNU and BSD tar differ in options such as --wildcards",
    ]

    /// What provides a command that a minimal image may lack, for the messages about missing commands.
    static let commandProviders: [String: String] = [
        "dot": "Graphviz", "javac": "a Java development kit", "java": "a Java runtime", "jar": "a Java development kit",
        "curl": "curl", "wget": "wget", "jq": "jq", "shasum": "Perl", "swift": "a Swift toolchain",
        "swiftc": "a Swift toolchain", "python3": "Python 3", "xmllint": "libxml2", "git": "Git",
        "zip": "zip", "unzip": "unzip", "bc": "bc", "make": "make", "tree": "tree",
    ]

    // MARK: - Failures in an output

    /// The comment line that marks a script as demonstrating an expected error.
    ///
    /// A script that contains a line starting with this comment demonstrates that a tool reports an
    /// error. Its step passes only if at least one tool invocation fails, and the exit status of the
    /// script and the `Error:` lines of the tools are then not counted as failures. Usage failures,
    /// such as an unknown command or option, still are. As the shell stops at the first failing
    /// command, the failing command should be the last one of such a script.
    static let expectedErrorMarker = "# Expected error"

    /// The prefix of a line with which a tool reports an error.
    static let errorPrefix = "Error:"

    /// The prefix of the line with which the argument parser shows the usage after an error.
    static let usagePrefix = "Usage:"

    /// The prefixes of the lines with which the argument parser rejects a command line.
    static let argumentErrorPrefixes = [
        "Error: Unknown option", "Error: Unexpected argument", "Error: Missing expected argument",
    ]

    /// The texts with which the shell reports that it could not run a command, at the end of a line.
    static let shellCommandFailures = ["command not found", "No such file or directory", "Permission denied"]

    /// The text that the shell puts before the line number of a message about a script line.
    static let shellLineMarker = ": line "

    /// The placeholder that replaces a date or a date and time.
    static let timestampPlaceholder = "<timestamp>"

    /// The placeholder that replaces a time of day.
    static let timePlaceholder = "<time>"

    /// The placeholder that replaces a duration with its unit.
    static let durationPlaceholder = "<duration>"

    // MARK: - Shell

    /// The shells that run the Terminal scripts, in order of preference.
    static let shellCandidates = ["/bin/bash", "/usr/bin/bash"]

    /// The options that make the shell stop at the first failing command of a script or pipeline.
    static let shellOptions = ["-e", "-o", "pipefail"]

    /// The directories of the base system that stay on the search path after the build products.
    static let systemSearchPath = ["/usr/bin", "/bin", "/usr/sbin", "/sbin"]

    /// The environment variable that holds the search path.
    static let searchPathVariable = "PATH"

    /// The separator of the directories of the search path.
    static let searchPathSeparator: Character = ":"

    /// The languages of fenced code blocks whose lines are shell commands.
    static let shellLanguages: Set<String> = ["bash", "sh", "shell", "zsh", "console", "shell-session"]

    /// The prompts that may precede a command in a fenced shell block.
    static let shellPrompts = ["$ ", "% "]

    // MARK: - Limits

    /// How long one Terminal step may run before it is stopped.
    static let stepTimeout: Duration = .seconds(600)

    /// How long the replay waits for the output of a stopped step to end.
    static let terminationGracePeriod: Duration = .seconds(5)

    /// The number of bytes of the output of a step that the replay keeps.
    static let outputByteLimit = 4 << 20

    /// The number of characters of an output that a failure message shows at its start and its end.
    static let reportedOutputCharacters = 4_000

    /// The environment variable that selects the tutorials to replay.
    ///
    /// When it is set, only tutorials whose identifier, such as `Ecore-CLI/01-first-metamodel`,
    /// contains one of its comma-separated values are replayed, together with the earlier
    /// tutorials of their series that they build on.
    static let selectionVariable = "TUTORIAL_REPLAY"

    /// The separator of the values of the selection variable.
    static let selectionSeparator: Character = ","

    /// The name of the directory, below the directory of the replays, that holds the wrappers of the
    /// tools of this build and the stand-ins for the tools that this build does not produce.
    static let toolsDirectoryName = "tools"

    /// The name of the directory, below the directory of the replays, that holds the logs of the
    /// tool invocations of every step.
    static let toolLogsDirectoryName = "tool-logs"

    /// The environment variable that names the directory in which the wrappers of the tools record
    /// the invocations of the current step.
    static let toolLogVariable = "TUTORIAL_REPLAY_TOOL_LOG"

    /// The extension of the file in which a wrapper records the standard error of an invocation.
    static let toolLogStandardErrorExtension = "stderr"

    /// The extension of the file in which a wrapper records the exit status and the arguments of an
    /// invocation once it has finished.
    static let toolLogStatusExtension = "status"

    /// The message with which the stand-in for a tool that this build does not produce reports it.
    static let missingToolMessage = "command not found (this build has no executable of that name)"

    /// The exit status of the stand-in for a missing tool, which the shell uses for an unknown command.
    static let missingToolStatus = 127

    /// The name of the directory below the temporary directory in which the replays run.
    static let workingDirectoryName = "swift-modelling-tutorial-replay"

    /// The reason that the replay does not run on Windows.
    static let windowsReason: Comment =
        "The tutorials show POSIX shell scripts, which need bash and process groups to replay"

    /// Whether the platform can replay the shell scripts of the tutorials.
    static var canReplayShellScripts: Bool {
        #if os(Windows)
            return false
        #else
            return true
        #endif
    }
}
