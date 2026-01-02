//
// Project.swift
// Generated from UML model
//

import Foundation

/// A project containing multiple tasks
class Project: Identifiable {

    // MARK: - Properties

    let id: String
    var name: String
    var tasks: [Task] = []
    var isActive: Bool = true

    // MARK: - Initialisation

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    // MARK: - Methods

    func addTask(task: Task) {
        // TODO: Implement addTask
    }

    func removeTask(taskId: String) {
        // TODO: Implement removeTask
    }

    func tasksWithPriority(priority: Priority) -> Task {
        // TODO: Implement tasksWithPriority
        fatalError("Not implemented")
    }

    func fetchRemoteTasks() async throws {
        // TODO: Implement fetchRemoteTasks
    }
}
