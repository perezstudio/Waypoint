//
//  DetailView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import SwiftData

struct DetailView: View {
	@Binding var isInspectorVisible: Bool
	@Binding var isSidebarCollapsed: Bool
	@Environment(ProjectStore.self) private var projectStore

	// Helper computed properties for view info
	private var viewIcon: String {
		switch projectStore.selectedView {
		case .system(let systemView):
			switch systemView {
			case .inbox: return "inbox.fill"
			case .today: return "calendar"
			case .upcoming: return "calendar.badge.clock"
			case .completed: return "checkmark.circle.fill"
			case .projects: return "folder.fill"
			}
		case .project:
			return projectStore.selectedProject?.icon ?? "folder.fill"
		}
	}

	private var viewName: String {
		switch projectStore.selectedView {
		case .system(let systemView):
			switch systemView {
			case .inbox: return "Inbox"
			case .today: return "Today"
			case .upcoming: return "Upcoming"
			case .completed: return "Completed"
			case .projects: return "Projects"
			}
		case .project:
			return projectStore.selectedProject?.name ?? "Project"
		}
	}

	private var shouldShowSegmentedPicker: Bool {
		if case .project = projectStore.selectedView {
			return true
		}
		return false
	}

	var body: some View {
		VStack(spacing: 0) {
			// Header toolbar
			HStack {
				// Left: Sidebar Toggle (when collapsed) + Icon + View Name
				HStack(spacing: 12) {
					// Sidebar toggle button - only show when sidebar is collapsed
					if isSidebarCollapsed {
						IconButton(
							icon: "sidebar.left",
							action: {
								withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
									isSidebarCollapsed = false
								}
							},
							tooltip: "Show Sidebar"
						)
						.transition(.move(edge: .leading).combined(with: .opacity))
					}

					Image(systemName: viewIcon)
						.font(.title2)
						.foregroundStyle(.secondary)

					Text(viewName)
						.font(.title2)
						.fontWeight(.semibold)
				}
				.animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSidebarCollapsed)

				Spacer()

				// Right: Segmented Picker + View Settings + Inspector Toggle
				HStack(spacing: 12) {
					// Segmented picker for project views (only show if project is selected)
					if shouldShowSegmentedPicker {
						Picker("View", selection: Binding(
							get: { projectStore.selectedViewType },
							set: { projectStore.selectedViewType = $0 }
						)) {
							ForEach(ProjectViewType.allCases, id: \.self) { viewType in
								Text(viewType.rawValue).tag(viewType)
							}
						}
						.pickerStyle(.segmented)
						.frame(width: 280)
					}

					// View settings button
					IconButton(
						icon: "ellipsis.circle",
						action: {
							// TODO: Show view settings popover
						},
						tooltip: "View Settings"
					)

					// Inspector toggle button
					IconButton(
						icon: "sidebar.right",
						action: {
							withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
								isInspectorVisible.toggle()
							}
						},
						isActive: isInspectorVisible,
						tooltip: "Toggle Inspector"
					)
				}
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 16)

			Divider()

			// Main content area
			ScrollView {
				VStack(alignment: .leading, spacing: 20) {
					// Content varies based on selected view
					switch projectStore.selectedView {
					case .system(let systemView):
						systemViewContent(for: systemView)
					case .project:
						projectViewContent()
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(20)
			}
		}
	}

	@ViewBuilder
	private func systemViewContent(for systemView: SystemView) -> some View {
		switch systemView {
		case .inbox:
			Text("Inbox Content")
				.foregroundStyle(.secondary)
		case .today:
			Text("Today's Tasks")
				.foregroundStyle(.secondary)
		case .upcoming:
			Text("Upcoming Tasks")
				.foregroundStyle(.secondary)
		case .completed:
			Text("Completed Tasks")
				.foregroundStyle(.secondary)
		case .projects:
			Text("All Projects")
				.foregroundStyle(.secondary)
		}
	}

	@ViewBuilder
	private func projectViewContent() -> some View {
		switch projectStore.selectedViewType {
		case .overview:
			ProjectOverviewView()
		case .issues:
			ProjectIssuesView()
		case .updates:
			ProjectUpdatesView()
		}
	}
}

// Placeholder views for different project view types
struct ProjectOverviewView: View {
	var body: some View {
		Text("Overview Content")
			.foregroundStyle(.secondary)
	}
}

struct ProjectIssuesView: View {
	var body: some View {
		Text("Issues Content")
			.foregroundStyle(.secondary)
	}
}

struct ProjectUpdatesView: View {
	var body: some View {
		Text("Updates Content")
			.foregroundStyle(.secondary)
	}
}

#Preview {
	DetailView(isInspectorVisible: .constant(false), isSidebarCollapsed: .constant(true))
		.environment(ProjectStore())
		.frame(width: 800, height: 600)
}
