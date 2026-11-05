import Foundation

/// Prints a progress report for the projects of a JSON model file.
///
/// The model is decoded into the Swift types that `GenerateSwiftModels.mtl`
/// generated from `ProjectManagement.ecore`.
@main
struct ProjectReport {
    /// Reads the file named on the command line and prints the report.
    static func main() throws {
        let arguments = CommandLine.arguments
        guard arguments.count == 2 else {
            print("Usage: project-report <model.json>")
            exit(2)
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
        let organisation = try JSONDecoder().decode(Organisation.self, from: data)
        let members = organisation.members ?? []
        print("Organisation: \(organisation.name ?? "unnamed")")
        for project in organisation.projects ?? [] {
            let tasks = project.tasks ?? []
            let completed = tasks.filter { $0.status == .completed }.count
            let actual = tasks.compactMap(\.actualHours).reduce(0, +)
            let estimated = tasks.compactMap(\.estimatedHours).reduce(0, +)
            print("\(project.name ?? "?") (\(project.status?.rawValue ?? "?")):"
                + " \(completed) of \(tasks.count) tasks completed,"
                + " \(actual) of \(estimated) estimated hours used")
            for task in tasks where task.status == .inProgress {
                let assignee = member(task.assignee, in: members)?.name ?? "unassigned"
                print("  in progress: \(task.title ?? "?") (\(assignee))")
            }
        }
    }

    /// Finds the team member that a reference such as `//@members.2` names.
    ///
    /// - Parameters:
    ///   - reference: The reference to resolve.
    ///   - members: The team members of the organisation.
    /// - Returns: The team member, or `nil` if the reference names none.
    static func member(_ reference: ModelReference?, in members: [TeamMember]) -> TeamMember? {
        let prefix = "//@members."
        guard let path = reference?.path, path.hasPrefix(prefix),
              let index = Int(path.dropFirst(prefix.count)), members.indices.contains(index)
        else { return nil }
        return members[index]
    }
}
