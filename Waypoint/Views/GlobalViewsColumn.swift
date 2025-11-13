//
//  GlobalViewsColumn.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct GlobalViewsColumn: View {
	@Environment(ProjectStore.self) private var projectStore
	@Query private var projects: [Project]

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			// Header
			VStack(alignment: .leading, spacing: 4) {
				Text("Global")
					.font(.caption)
					.foregroundStyle(.secondary)
					.padding(.leading, 8)
			}

			// System Views Section
			VStack(alignment: .leading, spacing: 4) {
				MenuItemView(
					icon: "tray.fill",
					label: "Inbox",
					count: 12,
					isSelected: projectStore.selectedView == .system(.inbox),
					iconColor: SystemView.inbox.color,
					action: { projectStore.selectSystemView(.inbox) }
				)
				MenuItemView(
					icon: SystemView.today.icon,
					label: "Today",
					count: 5,
					isSelected: projectStore.selectedView == .system(.today),
					iconColor: SystemView.today.color,
					action: { projectStore.selectSystemView(.today) }
				)
				MenuItemView(
					icon: "calendar.badge.clock",
					label: "Upcoming",
					count: 8,
					isSelected: projectStore.selectedView == .system(.upcoming),
					iconColor: SystemView.upcoming.color,
					action: { projectStore.selectSystemView(.upcoming) }
				)
				MenuItemView(
					icon: "checkmark.circle.fill",
					label: "Completed",
					isSelected: projectStore.selectedView == .system(.completed),
					iconColor: SystemView.completed.color,
					action: { projectStore.selectSystemView(.completed) }
				)
			}
		}
		.padding(.horizontal, 16)
		.frame(width: 260)
	}
}

#Preview {
	GlobalViewsColumn()
		.environment(ProjectStore())
		.modelContainer(for: [Project.self], inMemory: true)
}
