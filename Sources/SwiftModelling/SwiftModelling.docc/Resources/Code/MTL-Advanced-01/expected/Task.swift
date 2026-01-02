//
// Task.swift
// Generated from UML model
//

import Foundation

/// Represents a task in the system
struct Task: Identifiable {

    // MARK: - Properties

    let id: String
    var title: String
    var description: String? = nil
    var priority: Priority = .medium
    var status: Status = .pending
    var dueDate: Date? = nil
    var tags: [String] = []

    // MARK: - Initialisation

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    // MARK: - Methods

    func isOverdue(currentDate: Date) -> Bool {
        // TODO: Implement isOverdue
        return false
    }

    func markComplete() {
        // TODO: Implement markComplete
    }
}
