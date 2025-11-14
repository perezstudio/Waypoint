//
//  ProjectUpdate.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import Foundation
import SwiftData

@Model
final class ProjectUpdate {
    var id: UUID
    var content: String
    var author: String?
    var createdAt: Date

    var project: Project?

    init(content: String, author: String? = nil, project: Project? = nil) {
        self.id = UUID()
        self.content = content
        self.author = author
        self.createdAt = Date()
        self.project = project
    }
}
