//
//  Resource.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import Foundation
import SwiftData

enum ResourceType: String, Codable {
    case link = "Link"
    case file = "File"
}

@Model
final class Resource {
    var id: UUID
    var title: String
    var url: String
    var type: ResourceType
    var createdAt: Date

    var project: Project?

    init(title: String, url: String, type: ResourceType = .link, project: Project? = nil) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.type = type
        self.createdAt = Date()
        self.project = project
    }
}
