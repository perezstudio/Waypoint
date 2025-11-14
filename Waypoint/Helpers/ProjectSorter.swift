//
//  ProjectSorter.swift
//  Waypoint
//
//  Created by Claude on 11/13/25.
//

import Foundation

struct ProjectSorter {
    static func sort(_ projects: [Project], by sorting: ProjectSorting, direction: SortDirection) -> [Project] {
        let sorted: [Project]

        switch sorting {
        case .name:
            sorted = projects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .createdAt:
            sorted = projects.sorted { $0.createdAt < $1.createdAt }
        case .issueCount:
            sorted = projects.sorted { $0.issues.count < $1.issues.count }
        }

        return direction == .ascending ? sorted : sorted.reversed()
    }
}
