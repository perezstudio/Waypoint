//
//  SpaceColumn.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct SpaceColumn: View {
	let space: Space?  // nil means "All" view
	@Environment(ProjectStore.self) private var projectStore
	@Query private var projects: [Project]
	@Query private var labels: [Label]

	// Filtered projects for this space
	private var spaceProjects: [Project] {
		guard let space = space else { return projects }
		return projects.filter { $0.space?.id == space.id }
	}

	// Filtered labels for this space
	private var spaceLabels: [Label] {
		guard let space = space else { return labels }
		return labels.filter { $0.space?.id == space.id }
	}

	var body: some View {
		ScrollView(.vertical, showsIndicators: true) {
			VStack(alignment: .leading, spacing: 20) {
				// Global Views Section (at top of every space)
				VStack(alignment: .leading, spacing: 4) {
					MenuItemView(
						icon: "tray.fill",
						label: "Inbox",
						count: 12,
						isSelected: projectStore.selectedView == .system(.inbox),
						action: { projectStore.selectSystemView(.inbox) }
					)
					MenuItemView(
						icon: "calendar",
						label: "Today",
						count: 5,
						isSelected: projectStore.selectedView == .system(.today),
						action: { projectStore.selectSystemView(.today) }
					)
					MenuItemView(
						icon: "calendar.badge.clock",
						label: "Upcoming",
						count: 8,
						isSelected: projectStore.selectedView == .system(.upcoming),
						action: { projectStore.selectSystemView(.upcoming) }
					)
					MenuItemView(
						icon: "checkmark.circle.fill",
						label: "Completed",
						isSelected: projectStore.selectedView == .system(.completed),
						action: { projectStore.selectSystemView(.completed) }
					)
				}

				Divider()
					.padding(.vertical, 4)

				// Favorite Projects Section
				VStack(alignment: .leading, spacing: 8) {
					HStack {
						Text("Favorite Projects")
							.font(.caption)
							.foregroundStyle(.secondary)

						if space != nil {
							Text("(\(spaceProjects.count))")
								.font(.caption2)
								.foregroundStyle(.tertiary)
						}
					}
					.padding(.leading, 8)

					VStack(alignment: .leading, spacing: 4) {
						ForEach(spaceProjects) { project in
							MenuItemView(
								icon: project.icon,
								label: project.name,
								count: project.issues.count,
								isSelected: projectStore.selectedView == .project(project.id),
								action: { projectStore.selectProject(project) }
							)
						}

						if spaceProjects.isEmpty && space != nil {
							Text("No projects in this space")
								.font(.caption)
								.foregroundStyle(.tertiary)
								.frame(maxWidth: .infinity, alignment: .center)
								.padding(.vertical, 12)
						}
					}
				}

				Divider()
					.padding(.vertical, 4)

				// Favorite Labels Section
				VStack(alignment: .leading, spacing: 8) {
					HStack {
						Text("Favorite Labels")
							.font(.caption)
							.foregroundStyle(.secondary)

						if space != nil {
							Text("(\(spaceLabels.count))")
								.font(.caption2)
								.foregroundStyle(.tertiary)
						}
					}
					.padding(.leading, 8)

					VStack(alignment: .leading, spacing: 4) {
						ForEach(spaceLabels) { label in
							MenuItemView(
								icon: label.icon ?? "tag.fill",
								label: label.name,
								count: label.issues.count
							)
						}

						if spaceLabels.isEmpty && space != nil {
							Text("No labels in this space")
								.font(.caption)
								.foregroundStyle(.tertiary)
								.frame(maxWidth: .infinity, alignment: .center)
								.padding(.vertical, 12)
						}
					}
				}
			}
			.padding(.horizontal, 16)
			.frame(maxWidth: .infinity, alignment: .top)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
	}
}
