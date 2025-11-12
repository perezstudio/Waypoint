//
//  Label.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import Foundation
import SwiftData

@Model
final class Label {
    var id: UUID
    var name: String
    var color: String  // Hex color code
    var icon: String?  // Optional SF Symbol name
    var createdAt: Date

    @Relationship(inverse: \Issue.labels)
    var issues: [Issue] = []

    init(name: String, color: String, icon: String? = nil) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = Date()
    }
}
