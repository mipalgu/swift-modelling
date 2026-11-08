//
//  CompatibilityReport.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

/// The outcome of a subtyping check.
///
/// The report states whether the module can run on models of the provided
/// metamodels, why not, which elements it uses, and which renamings might
/// reconcile missing elements.
public struct CompatibilityReport: Sendable, Hashable, Codable {
    /// The subtyping relation that was decided.
    public let mode: SubtypingMode
    /// The findings, most serious and then by element.
    public let diagnostics: [TypingDiagnostic]
    /// The footprint of the module, if one was extracted or given.
    public let footprint: Footprint?
    /// Suggested renamings for missing elements, closest first per element.
    public let renamingHints: [RenamingHint]

    /// Creates a report.
    ///
    /// - Parameters:
    ///   - mode: The subtyping relation that was decided.
    ///   - diagnostics: The findings.
    ///   - footprint: The footprint of the module, if any.
    ///   - renamingHints: Suggested renamings.
    public init(mode: SubtypingMode, diagnostics: [TypingDiagnostic], footprint: Footprint?, renamingHints: [RenamingHint]) {
        self.mode = mode
        self.diagnostics = diagnostics
        self.footprint = footprint
        self.renamingHints = renamingHints
    }

    /// Whether the provided metamodels are subtypes of the required ones in the checked mode.
    public var compatible: Bool { !diagnostics.contains { $0.severity == .error } }

    /// Whether the verdict rests on complete static knowledge of the module's footprint.
    ///
    /// A verdict is inconclusive when footprint extraction met expressions whose
    /// types it could not infer; uses guessed there are checked, but only
    /// reported as warnings.
    public var isConclusive: Bool { footprint?.isComplete ?? true }

    /// The findings with error severity.
    public var errors: [TypingDiagnostic] { diagnostics.filter { $0.severity == .error } }

    /// The findings with warning severity.
    public var warnings: [TypingDiagnostic] { diagnostics.filter { $0.severity == .warning } }

    /// The findings with a given code.
    ///
    /// - Parameter code: The code.
    /// - Returns: The findings with that code.
    public func diagnostics(withCode code: TypingDiagnosticCode) -> [TypingDiagnostic] {
        diagnostics.filter { $0.code == code }
    }

    /// A renaming that applies the closest hint for every missing element.
    public var suggestedRenaming: Renaming {
        var renaming = Renaming()
        for hint in renamingHints {
            switch hint.kind {
            case .classifier:
                if renaming.classifiers[hint.requiredName] == nil {
                    renaming.classifiers[hint.requiredName] = hint.suggestedName
                }
            case .feature, .literal:
                let key = Renaming.memberKey(owner: hint.owner ?? "", member: hint.requiredName)
                if renaming.members[key] == nil { renaming.members[key] = hint.suggestedName }
            }
        }
        return renaming
    }

    /// The order of findings: by severity, then element, then code.
    ///
    /// - Parameters:
    ///   - lhs: The first finding.
    ///   - rhs: The second finding.
    /// - Returns: `true` if `lhs` is listed before `rhs`.
    public static func ordering(_ lhs: TypingDiagnostic, _ rhs: TypingDiagnostic) -> Bool {
        if lhs.severity != rhs.severity { return lhs.severity < rhs.severity }
        if lhs.element != rhs.element { return lhs.element < rhs.element }
        if lhs.code != rhs.code { return lhs.code.rawValue < rhs.code.rawValue }
        return lhs.message < rhs.message
    }

    /// The report as text, suitable for a command line tool.
    ///
    /// The first line states the verdict; findings, footprint uncertainties and
    /// renaming hints follow, one per line.
    ///
    /// - Parameter includesNotes: Whether findings with note severity are listed (default: `false`).
    /// - Returns: The text.
    public func formatted(includesNotes: Bool = false) -> String {
        let verdict = compatible ? "compatible" : "incompatible"
        var lines = ["\(verdict) (\(mode.rawValue)\(isConclusive ? "" : ", inconclusive")): "
            + "\(errors.count) error(s), \(warnings.count) warning(s)"]
        for diagnostic in diagnostics where includesNotes || diagnostic.severity != .note {
            lines.append(diagnostic.description)
        }
        for uncertainty in footprint?.uncertainties ?? [] {
            lines.append("uncertain: \(uncertainty)")
        }
        for hint in renamingHints {
            lines.append("hint: --rename \(hint.renamingEntry) (\(hint.reason.rawValue))")
        }
        return lines.joined(separator: "\n")
    }
}
