//
// TaskRepository.swift
// Generated from UML model
//

import Foundation

/// Protocol for task persistence
protocol TaskRepository {
    func save(task: Task) throws
    func findById(id: String) -> Task?
    func findAll() -> [Task]
    func delete(id: String) throws
}
