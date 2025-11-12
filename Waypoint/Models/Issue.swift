//
//  Issue.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import Foundation
import SwiftData

enum IssueStatus: String, Codable {
    case todo
    case inProgress
    case review
    case done
}

enum IssuePriority: String, Codable {
    case low
    case medium
    case high
    case urgent
}

@Model
final class Issue {
    var id: UUID
    var title: String
    var issueDescription: String?
    var status: IssueStatus
    var priority: IssuePriority
    var createdAt: Date
    var updatedAt: Date
    var dueDate: Date?

    var project: Project?
    var tags: [Tag] = []

    init(title: String, status: IssueStatus = .todo, priority: IssuePriority = .medium, project: Project? = nil) {
        self.id = UUID()
        self.title = title
        self.status = status
        self.priority = priority
        self.createdAt = Date()
        self.updatedAt = Date()
        self.project = project
    }
}
