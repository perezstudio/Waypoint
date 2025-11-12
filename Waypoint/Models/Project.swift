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
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Issue.project)
    var issues: [Issue] = []

    var team: Team?

    init(name: String, icon: String = "folder.fill", color: String = "#007AFF", team: Team? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
        self.team = team
    }
}
