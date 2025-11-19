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
    var favorite: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Issue.project)
    var issues: [Issue] = []

    @Relationship(deleteRule: .cascade, inverse: \Resource.project)
    var resources: [Resource] = []

    @Relationship(deleteRule: .cascade, inverse: \ProjectUpdate.project)
    var updates: [ProjectUpdate] = []

    @Relationship(deleteRule: .cascade, inverse: \Milestone.project)
    var milestones: [Milestone] = []

    @Relationship(deleteRule: .cascade, inverse: \ContentBlock.project)
    var contentBlocks: [ContentBlock] = []

    @Relationship(deleteRule: .cascade, inverse: \ProjectIssuesViewSettings.project)
    var viewSettings: ProjectIssuesViewSettings?

    var space: Space?

    init(name: String, icon: String = "folder.fill", color: String = "#007AFF", status: Status = .inProgress, space: Space? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
        self.favorite = false
        self.space = space

        // Create default view settings for new projects
        self.viewSettings = ProjectIssuesViewSettings(project: nil)
    }
}
