//
//  ProjectStore.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import Foundation
import SwiftUI

enum SystemView: Hashable {
    case inbox
    case today
    case upcoming
    case completed
    case projects

    var color: Color {
        switch self {
        case .inbox: return .blue
        case .today: return .yellow
        case .upcoming: return .red
        case .completed: return .green
        case .projects: return .purple
        }
    }

    var icon: String {
        switch self {
        case .inbox: return "tray.fill"
        case .today:
            let day = Calendar.current.component(.day, from: Date())
            return "\(day).calendar"
        case .upcoming: return "calendar.badge.clock"
        case .completed: return "checkmark.circle.fill"
        case .projects: return "folder.fill"
        }
    }
}

enum SelectedView: Hashable {
    case system(SystemView)
    case project(UUID)  // Store project ID
}

enum ProjectViewType: String, CaseIterable {
    case overview = "Overview"
    case issues = "Issues"
    case updates = "Updates"
}

enum IssuesViewMode: String, CaseIterable, Codable {
    case list = "List"
    case board = "Board"
}

@Observable
class ProjectStore {
    var selectedView: SelectedView = .system(.inbox)
    var selectedProject: Project?
    var selectedViewType: ProjectViewType = .overview
    var issuesViewMode: IssuesViewMode = .board
    var selectedIssue: Issue?
    var cameFromProjectsList: Bool = false

    init() {}

    func selectSystemView(_ systemView: SystemView) {
        self.selectedView = .system(systemView)
        self.selectedProject = nil
        self.selectedViewType = .overview
        self.cameFromProjectsList = false
    }

    func selectProject(_ project: Project?, cameFromProjectsList: Bool = false) {
        guard let project = project else {
            selectSystemView(.inbox)
            return
        }
        self.selectedView = .project(project.id)
        self.selectedProject = project
        // Reset to overview when selecting a new project
        self.selectedViewType = .overview
        self.cameFromProjectsList = cameFromProjectsList
    }
}
