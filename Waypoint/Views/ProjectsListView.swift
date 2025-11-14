//
//  ProjectsListView.swift
//  Waypoint
//
//  Created by Claude on 11/13/25.
//

import SwiftUI
import SwiftData

struct ProjectsListView: View {
    @Environment(ViewSettingsStore.self) private var viewSettingsStore
    @Environment(ProjectStore.self) private var projectStore
    @Query private var allProjects: [Project]
    @State private var showingCreateProject = false

    private var settings: ProjectViewSettings {
        viewSettingsStore.projectsSettings
    }

    private var sortedProjects: [Project] {
        ProjectSorter.sort(allProjects, by: settings.sortBy, direction: settings.sortDirection)
    }

    private var groupedProjects: [ProjectGroup] {
        ProjectGrouper.group(sortedProjects, by: settings.groupBy)
    }

    var body: some View {
        Group {
            if allProjects.isEmpty {
                emptyStateView
            } else {
                switch settings.viewMode {
                case .board:
                    GenericProjectBoardView(
                        groups: groupedProjects,
                        showAddButton: true,
                        onAddProject: { showingCreateProject = true },
                        onSelectProject: { project in
                            projectStore.selectProject(project, cameFromProjectsList: true)
                        }
                    )
                case .list:
                    ScrollView {
                        GenericProjectListView(
                            groups: groupedProjects,
                            showAddButton: true,
                            onAddProject: { showingCreateProject = true },
                            onSelectProject: { project in
                                projectStore.selectProject(project, cameFromProjectsList: true)
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectSheet()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Projects")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a project to get started")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    ProjectsListView()
        .environment(ViewSettingsStore())
        .environment(ProjectStore())
        .modelContainer(for: [Project.self, Space.self], inMemory: true)
}
