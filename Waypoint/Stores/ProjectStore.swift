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

@Observable
class ProjectStore {
    var selectedView: SelectedView = .system(.inbox)
    var selectedProject: Project?
    var selectedViewType: ProjectViewType = .overview

    init() {}

    func selectSystemView(_ systemView: SystemView) {
        self.selectedView = .system(systemView)
        self.selectedProject = nil
        self.selectedViewType = .overview
    }

    func selectProject(_ project: Project?) {
        guard let project = project else {
            selectSystemView(.inbox)
            return
        }
        self.selectedView = .project(project.id)
        self.selectedProject = project
        // Reset to overview when selecting a new project
        self.selectedViewType = .overview
    }
}
