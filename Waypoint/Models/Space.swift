//
//  Space.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import Foundation
import SwiftData

@Model
final class Space {
    var id: UUID
    var name: String
    var spaceDescription: String?
    var icon: String  // SF Symbol name
    var color: String  // Hex color code
    var createdAt: Date
    var sort: Int  // For manual ordering of spaces

    @Relationship(deleteRule: .nullify, inverse: \Project.space)
    var projects: [Project] = []

    @Relationship(deleteRule: .nullify, inverse: \Tag.space)
    var tags: [Tag] = []

    init(name: String, spaceDescription: String? = nil, icon: String = "person.3.fill", color: String = "#007AFF", sort: Int = 0) {
        self.id = UUID()
        self.name = name
        self.spaceDescription = spaceDescription
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.sort = sort
    }
}
