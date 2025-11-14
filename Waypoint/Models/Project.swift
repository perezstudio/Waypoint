//
//  Project.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var icon: String  // SF Symbol name
    var color: String  // Hex color code
    var status: Status
    var projectDescription: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Issue.project)
    var issues: [Issue] = []

    @Relationship(deleteRule: .cascade, inverse: \Resource.project)
    var resources: [Resource] = []

    @Relationship(deleteRule: .cascade, inverse: \ProjectUpdate.project)
    var updates: [ProjectUpdate] = []

    @Relationship(deleteRule: .cascade, inverse: \Milestone.project)
    var milestones: [Milestone] = []

    var space: Space?

    init(name: String, icon: String = "folder.fill", color: String = "#007AFF", status: Status = .inProgress, space: Space? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
        self.space = space
    }
}
