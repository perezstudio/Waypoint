//
//  Milestone.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import Foundation
import SwiftData

@Model
final class Milestone {
    var id: UUID
    var title: String
    var milestoneDescription: String?
    var dueDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var order: Int
    var createdAt: Date

    var project: Project?

    init(title: String, description: String? = nil, dueDate: Date? = nil, order: Int = 0, project: Project? = nil) {
        self.id = UUID()
        self.title = title
        self.milestoneDescription = description
        self.dueDate = dueDate
        self.isCompleted = false
        self.order = order
        self.createdAt = Date()
        self.project = project
    }
}
