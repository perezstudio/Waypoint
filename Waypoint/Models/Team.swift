//
//  Team.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import Foundation
import SwiftData

@Model
final class Team {
    var id: UUID
    var name: String
    var teamDescription: String?
    var icon: String  // SF Symbol name
    var color: String  // Hex color code
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Project.team)
    var projects: [Project] = []

    init(name: String, teamDescription: String? = nil, icon: String = "person.3.fill", color: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.teamDescription = teamDescription
        self.icon = icon
        self.color = color
        self.createdAt = Date()
    }
}
