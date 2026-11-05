//
// ScriptCommandsTests.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests of the detection of the commands that a script needs, and of the check before a replay.
@Suite("Commands that tutorial scripts need")
struct ScriptCommandsTests {
    /// The names of the installed commands of a script, in script order.
    ///
    /// - Parameter script: The text of a script.
    /// - Returns: The command names.
    func names(_ script: String) -> [String] {
        ScriptCommands.externalCommands(in: script).map(\.name)
    }

    @Test("Commands at the start of lines and after control operators are found with their lines")
    func simpleCommands() {
        let found = ScriptCommands.externalCommands(in: "mkdir -p out\ncurl -LO https://example.org/a\n")
        #expect(found == [ScriptCommand(name: "mkdir", line: 1), ScriptCommand(name: "curl", line: 2)])
        #expect(names("grep a f | sort | uniq -c && wc -l f || true; ls &") == ["grep", "sort", "uniq", "wc", "ls"])
    }

    @Test("Builtins, tools of this package, paths, variables and assignments are not installed commands")
    func excludedNames() {
        #expect(names("echo hi; cd x; swift-ecore validate a; ./run.sh; Scripts/x.sh; \"$TOOL\" x") == [])
        #expect(names("A=1 B=\"two words\" make all") == ["make"])
        #expect(names("files=(a b c)\nexport X=1") == [])
    }

    @Test("Here-documents, comments and quoted text are not read as commands")
    func hereDocumentsAndQuotes() {
        let script = """
            cat > notes.txt << 'EOF'
            notacommand arg
              EOF still inside
            EOF
            # comment with dot -Tsvg
            echo "javac is not run here" 'nor | curl here'
            tr a b <<-END
            \tignored
            \tEND
            ls
            """
        #expect(names(script) == ["cat", "tr", "ls"])
    }

    @Test("Substitutions, backticks and process substitutions are read as scripts")
    func substitutions() {
        let script = "X=\"$(find src -name '*.java')\"\ny=`date`\necho \"$(jq . a.json)\"\ndiff <(sort a) <(sort b)"
        #expect(Set(names(script)) == ["find", "date", "jq", "diff", "sort"])
        #expect(ScriptCommands.externalCommands(in: script).first { $0.name == "jq" }?.line == 3)
    }

    @Test("Loops, cases, tests, arithmetic and functions are understood")
    func compoundCommands() {
        let script = """
            check() { diff a b; }
            for f in alpha beta; do dot -Tsvg "$f"; done
            case "$x" in
              a|b) shasum -a 256 x ;;
              *.xmi) sha256sum x ;;
            esac
            if [[ -f x && -d y ]]; then javac A.java; fi
            (( i++ ))
            check
            function report { awk '{print}' f; }
            report
            """
        #expect(names(script) == ["diff", "dot", "shasum", "sha256sum", "javac", "awk"])
    }

    @Test("Commands run by wrappers count, and command lookups do not")
    func wrappers() {
        #expect(names("xargs -I {} cp {} dest") == ["xargs", "cp"])
        #expect(names("find . -name '*.x' -exec grep -l y {} \\;") == ["find", "grep"])
        #expect(names("env A=1 swiftc x.swift") == ["env", "swiftc"])
        #expect(names("command -v dot >/dev/null 2>&1") == [])
        #expect(names("timeout 5 sleep 1") == ["timeout", "sleep"])
        #expect(names("java -jar x.jar > out.txt 2>&1 && sort < in.txt") == ["java", "sort"])
    }

    @Test("Line continuations keep the line of the command")
    func continuations() {
        #expect(ScriptCommands.externalCommands(in: "\njavac \\\n  -d classes A.java\n") == [ScriptCommand(name: "javac", line: 2)])
        let substituted = "x=$(swift-aql query m \\\n  \"q\")\ndiff a b\n"
        #expect(ScriptCommands.externalCommands(in: substituted) == [ScriptCommand(name: "diff", line: 3)])
    }

    @Test("The message names each missing command, its provider and the lines that need it")
    func missingCommandsMessage() {
        let required: [String: [CommandUse]] = [
            "dot": [CommandUse(tutorial: "S/One", script: "one.sh", line: 10)],
            "ls": [CommandUse(tutorial: "S/One", script: "one.sh", line: 1)],
            "javac": [
                CommandUse(tutorial: "S/Two", script: "two.sh", line: 2),
                CommandUse(tutorial: "S/Two", script: "three.sh", line: 4),
            ],
        ]
        let present = TutorialReplayEnvironment.missingCommandsMessage(series: "S", required: required) { "/bin/\($0)" }
        #expect(present == nil)
        let message = TutorialReplayEnvironment.missingCommandsMessage(series: "S", required: required) {
            $0 == "ls" ? "/bin/ls" : nil
        }
        #expect(message?.hasPrefix("Series S was not replayed: it needs dot (Graphviz), javac (a Java development kit), which are not installed") == true)
        #expect(message?.contains("dot is needed by S/One:\n    S/One: one.sh line 10") == true)
        #expect(message?.contains("    S/Two: three.sh line 4") == true)
        #expect(message?.contains("ls") == false)
    }

    @Test(
        "A series that needs a missing command is reported and not replayed",
        .enabled(if: TutorialReplayConfiguration.canReplayShellScripts, TutorialReplayConfiguration.windowsReason))
    func seriesNotReplayed() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let catalogue = root.appendingPathComponent("Example.docc")
        let files = [
            "Tutorials/Series/First.tutorial": "@Tutorial { @Code(name: \"Terminal\", file: first.sh) }",
            "Tutorials/Series/Second.tutorial": "@Tutorial { @Code(name: \"Terminal\", file: second.sh) }",
            "Resources/first.sh": "touch ran\n",
            "Resources/second.sh": "ls\nsurely-not-an-installed-command --now\n",
        ]
        for (path, text) in files {
            let url = catalogue.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
        let loaded = try TutorialCatalogue(root: catalogue)
        let first = try #require(loaded.tutorials.first { $0.name == "First" })
        let coordinator = TutorialReplayCoordinator()

        let report = try await coordinator.report(
            for: first, in: loaded, environment: try TutorialReplayEnvironment.shared.get())

        let reason = try #require(report.notReplayedReason)
        #expect(reason.contains("surely-not-an-installed-command is needed by Series/Second"))
        #expect(reason.contains("second.sh line 2"))
        #expect(report.failures.isEmpty && report.passedSteps == 0 && report.terminalSteps == 1)
        #expect(!FileManager.default.fileExists(atPath: report.directory.appendingPathComponent("Series/ran").path))
    }
}
