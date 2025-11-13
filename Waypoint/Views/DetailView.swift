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
	@Environment(ViewSettingsStore.self) private var viewSettingsStore

	// Helper computed properties for view info
	private var viewIcon: String {
		switch projectStore.selectedView {
		case .system(let systemView):
			return systemView.icon
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

	private var viewColor: Color {
		switch projectStore.selectedView {
		case .system(let systemView):
			return systemView.color
		case .project:
			if let project = projectStore.selectedProject {
				return AppColor.color(from: project.color)
			}
			return .blue
		}
	}

	private var shouldShowSegmentedPicker: Bool {
		if case .project = projectStore.selectedView {
			return true
		}
		return false
	}

	private var shouldShowViewSettingsToolbar: Bool {
		switch projectStore.selectedView {
		case .system(let systemView):
			// Show for inbox, today, upcoming, completed
			return systemView != .projects
		case .project:
			// Show for project issues view
			return projectStore.selectedViewType == .issues
		}
	}

	private var currentViewSettings: Binding<ViewSettings>? {
		switch projectStore.selectedView {
		case .system(let systemView):
			switch systemView {
			case .inbox:
				return Binding(
					get: { viewSettingsStore.inboxSettings },
					set: { viewSettingsStore.updateSettings($0, for: .inbox) }
				)
			case .today:
				return Binding(
					get: { viewSettingsStore.todaySettings },
					set: { viewSettingsStore.updateSettings($0, for: .today) }
				)
			case .upcoming:
				return Binding(
					get: { viewSettingsStore.upcomingSettings },
					set: { viewSettingsStore.updateSettings($0, for: .upcoming) }
				)
			case .completed:
				return Binding(
					get: { viewSettingsStore.completedSettings },
					set: { viewSettingsStore.updateSettings($0, for: .completed) }
				)
			case .projects:
				return nil
			}
		case .project:
			// For now, return nil for projects - we can add project-specific settings later
			return nil
		}
	}

	private var currentSystemView: SystemView? {
		if case .system(let systemView) = projectStore.selectedView {
			return systemView
		}
		return nil
	}

	var body: some View {
		DetailViewSplitView(
			content: mainContent,
			inspector: InspectorView(isVisible: $isInspectorVisible),
			isInspectorVisible: $isInspectorVisible
		)
	}

	private var mainContent: some View {
		VStack(spacing: 0) {
			// Header toolbar
			HStack(alignment: .center) {
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
						.foregroundStyle(viewColor)

					Text(viewName)
						.font(.title2)
						.fontWeight(.semibold)
				}
				.animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSidebarCollapsed)

				Spacer()

				// Middle: View Settings Controls (when applicable)
				if shouldShowViewSettingsToolbar, let settings = currentViewSettings {
					HStack(alignment: .center, spacing: 24) {
						// View mode picker
						VStack(alignment: .center, spacing: 4) {
							if viewSettingsStore.controlDisplayMode == .textOnly {
								Picker("", selection: Binding(
									get: { settings.wrappedValue.viewMode },
									set: {
										var newSettings = settings.wrappedValue
										newSettings.viewMode = $0
										settings.wrappedValue = newSettings
									}
								)) {
									ForEach(IssuesViewMode.allCases, id: \.self) { mode in
										Text(mode.rawValue).tag(mode)
									}
								}
								.labelsHidden()
								.pickerStyle(.segmented)
								.help("View mode")
							} else {
								Picker("", selection: Binding(
									get: { settings.wrappedValue.viewMode },
									set: {
										var newSettings = settings.wrappedValue
										newSettings.viewMode = $0
										settings.wrappedValue = newSettings
									}
								)) {
									ForEach(IssuesViewMode.allCases, id: \.self) { mode in
										Image(systemName: mode == .board ? "square.grid.2x2" : "list.bullet")
											.tag(mode)
									}
								}
								.labelsHidden()
								.pickerStyle(.segmented)
								.help("View mode")
							}

							if viewSettingsStore.controlDisplayMode != .iconOnly {
								Text("View")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}

						// Group by menu
						ViewControlMenu(
							icon: settings.wrappedValue.groupBy.icon,
							text: "Group",
							selectedText: settings.wrappedValue.groupBy.rawValue
						) {
							ForEach(IssueGrouping.allCases, id: \.self) { grouping in
								Button(action: {
									var newSettings = settings.wrappedValue
									newSettings.groupBy = grouping
									settings.wrappedValue = newSettings
								}) {
									HStack {
										Image(systemName: grouping.icon)
										Text(grouping.rawValue)
										if settings.wrappedValue.groupBy == grouping {
											Spacer()
											Image(systemName: "checkmark")
										}
									}
								}
							}
						}

						// Sort controls
						VStack(alignment: .center, spacing: 4) {
							HStack(spacing: 6) {
								// Sort by menu
								ViewControlMenu(
									icon: settings.wrappedValue.sortBy.icon,
									text: "Sort",
									selectedText: settings.wrappedValue.sortBy.rawValue,
									showLabel: false
								) {
									ForEach(IssueSorting.allCases, id: \.self) { sorting in
										Button(action: {
											var newSettings = settings.wrappedValue
											newSettings.sortBy = sorting
											settings.wrappedValue = newSettings
										}) {
											HStack {
												Image(systemName: sorting.icon)
												Text(sorting.rawValue)
												if settings.wrappedValue.sortBy == sorting {
													Spacer()
													Image(systemName: "checkmark")
												}
											}
										}
									}
								}

								// Sort direction button
								ViewControlButton(
									icon: settings.wrappedValue.sortDirection.icon,
									text: settings.wrappedValue.sortDirection.rawValue,
									showLabel: false
								) {
									var newSettings = settings.wrappedValue
									newSettings.sortDirection = newSettings.sortDirection == .ascending ? .descending : .ascending
									settings.wrappedValue = newSettings
								}
							}

							if viewSettingsStore.controlDisplayMode != .iconOnly {
								Text("Sort")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
					}
				}

				// Right: Segmented Picker + Inspector Toggle
				HStack(alignment: .center, spacing: 24) {
					// Segmented picker for project views (only show if project is selected)
					if shouldShowSegmentedPicker {
						Picker("", selection: Binding(
							get: { projectStore.selectedViewType },
							set: { projectStore.selectedViewType = $0 }
						)) {
							ForEach(ProjectViewType.allCases, id: \.self) { viewType in
								Text(viewType.rawValue).tag(viewType)
							}
						}
						.labelsHidden()
						.pickerStyle(.segmented)
					}

					// Inspector toggle button - hide when inspector is open
					if !isInspectorVisible {
						VStack(alignment: .center, spacing: 4) {
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

							if viewSettingsStore.controlDisplayMode != .iconOnly {
								Text("Inspector")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
						.transition(.asymmetric(
							insertion: .move(edge: .trailing).combined(with: .opacity),
							removal: .move(edge: .trailing).combined(with: .opacity)
						))
					}
				}
				.animation(.spring(response: 0.3, dampingFraction: 0.8), value: isInspectorVisible)
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 16)
			.frame(maxHeight: 60)
			.clipped()

			Divider()

			// Main content area
			// System views manage their own layout, project views need ScrollView
			switch projectStore.selectedView {
			case .system(let systemView):
				systemViewContent(for: systemView)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			case .project:
				ScrollView {
					VStack(alignment: .leading, spacing: 20) {
						projectViewContent()
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(20)
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.clipped()
	}

	@ViewBuilder
	private func systemViewContent(for systemView: SystemView) -> some View {
		switch systemView {
		case .inbox:
			InboxView(isInspectorVisible: $isInspectorVisible)
		case .today:
			TodayView(isInspectorVisible: $isInspectorVisible)
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
			ProjectIssuesView(isInspectorVisible: $isInspectorVisible)
		case .updates:
			ProjectUpdatesView()
		}
	}
}

// Placeholder views for different project view types
struct ProjectOverviewView: View {
	@Environment(ProjectStore.self) private var projectStore
	@Query private var allIssues: [Issue]

	private var projectIssues: [Issue] {
		guard let project = projectStore.selectedProject else { return [] }
		return allIssues.filter { $0.project?.id == project.id }
	}

	private var issuesByStatus: [IssueStatus: Int] {
		Dictionary(grouping: projectIssues, by: { $0.status })
			.mapValues { $0.count }
	}

	private var issuesByPriority: [IssuePriority: Int] {
		Dictionary(grouping: projectIssues, by: { $0.priority })
			.mapValues { $0.count }
	}

	private var completionPercentage: Double {
		guard !projectIssues.isEmpty else { return 0 }
		let completed = issuesByStatus[.done] ?? 0
		return Double(completed) / Double(projectIssues.count)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 24) {
			// Stats Grid
			LazyVGrid(columns: [
				GridItem(.flexible()),
				GridItem(.flexible()),
				GridItem(.flexible()),
				GridItem(.flexible())
			], spacing: 16) {
				StatCard(title: "Total Issues", value: "\(projectIssues.count)", icon: "list.bullet", color: .blue)
				StatCard(title: "To Do", value: "\(issuesByStatus[.todo] ?? 0)", icon: "circle", color: .gray)
				StatCard(title: "In Progress", value: "\(issuesByStatus[.inProgress] ?? 0)", icon: "arrow.right.circle.fill", color: .orange)
				StatCard(title: "Completed", value: "\(issuesByStatus[.done] ?? 0)", icon: "checkmark.circle.fill", color: .green)
			}

			// Progress Section
			VStack(alignment: .leading, spacing: 12) {
				HStack {
					Text("Overall Progress")
						.font(.headline)
					Spacer()
					Text("\(Int(completionPercentage * 100))%")
						.font(.headline)
						.foregroundStyle(.secondary)
				}

				ProgressView(value: completionPercentage)
					.tint(.green)
			}
			.padding()
			.background(.bar)
			.clipShape(RoundedRectangle(cornerRadius: 8))

			// Priority Breakdown
			VStack(alignment: .leading, spacing: 12) {
				Text("By Priority")
					.font(.headline)

				HStack(spacing: 16) {
					PriorityBadge(priority: .urgent, count: issuesByPriority[.urgent] ?? 0)
					PriorityBadge(priority: .high, count: issuesByPriority[.high] ?? 0)
					PriorityBadge(priority: .medium, count: issuesByPriority[.medium] ?? 0)
					PriorityBadge(priority: .low, count: issuesByPriority[.low] ?? 0)
					Spacer()
				}
			}
			.padding()
			.background(.bar)
			.clipShape(RoundedRectangle(cornerRadius: 8))

			Spacer()
		}
	}
}

struct StatCard: View {
	let title: String
	let value: String
	let icon: String
	let color: Color

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Image(systemName: icon)
					.foregroundStyle(color)
				Spacer()
			}

			Text(value)
				.font(.title)
				.fontWeight(.semibold)

			Text(title)
				.font(.caption)
				.foregroundStyle(.secondary)
		}
		.padding()
		.background(.bar)
		.clipShape(RoundedRectangle(cornerRadius: 8))
	}
}

struct PriorityBadge: View {
	let priority: IssuePriority
	let count: Int

	private var priorityColor: Color {
		switch priority {
		case .urgent: return .red
		case .high: return .orange
		case .medium: return .blue
		case .low: return .gray
		}
	}

	private var priorityIcon: String {
		switch priority {
		case .urgent: return "exclamationmark.3"
		case .high: return "exclamationmark.2"
		case .medium: return "equal"
		case .low: return "minus"
		}
	}

	var body: some View {
		HStack(spacing: 6) {
			Image(systemName: priorityIcon)
				.font(.caption2)
				.foregroundStyle(priorityColor)

			Text(priority.rawValue.capitalized)
				.font(.caption)
				.foregroundStyle(.primary)

			Text("\(count)")
				.font(.caption)
				.foregroundStyle(.secondary)
				.padding(.horizontal, 6)
				.padding(.vertical, 2)
				.background(.tertiary.opacity(0.5))
				.clipShape(RoundedRectangle(cornerRadius: 4))
		}
		.padding(.horizontal, 10)
		.padding(.vertical, 6)
		.background(priorityColor.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 6))
	}
}

struct ProjectIssuesView: View {
	@Environment(ProjectStore.self) private var projectStore
	@Query private var allIssues: [Issue]
	@State private var showingCreateIssue = false
	@State private var createIssueForStatus: IssueStatus?
	@Binding var isInspectorVisible: Bool

	private var projectIssues: [Issue] {
		guard let project = projectStore.selectedProject else { return [] }
		return allIssues.filter { $0.project?.id == project.id }
	}

	private var issuesByStatus: [IssueStatus: [Issue]] {
		Dictionary(grouping: projectIssues, by: { $0.status })
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			// Content based on view mode
			switch projectStore.issuesViewMode {
			case .board:
				IssueBoardView(
					issuesByStatus: issuesByStatus,
					onAddIssue: { status in
						createIssueForStatus = status
						showingCreateIssue = true
					},
					isInspectorVisible: $isInspectorVisible
				)
			case .list:
				IssueListView(
					issuesByStatus: issuesByStatus,
					onAddIssue: { status in
						createIssueForStatus = status
						showingCreateIssue = true
					},
					isInspectorVisible: $isInspectorVisible
				)
			}
		}
		.sheet(isPresented: $showingCreateIssue) {
			if let status = createIssueForStatus {
				CreateIssueSheet(defaultStatus: status, project: projectStore.selectedProject)
			}
		}
	}
}

// Board View
struct IssueBoardView: View {
	let issuesByStatus: [IssueStatus: [Issue]]
	let onAddIssue: (IssueStatus) -> Void
	@Binding var isInspectorVisible: Bool

	var body: some View {
		HStack(alignment: .top, spacing: 16) {
			IssueColumn(
				title: "To Do",
				status: .todo,
				issues: issuesByStatus[.todo] ?? [],
				color: .gray,
				onAddIssue: onAddIssue,
				isInspectorVisible: $isInspectorVisible
			)
			IssueColumn(
				title: "In Progress",
				status: .inProgress,
				issues: issuesByStatus[.inProgress] ?? [],
				color: .orange,
				onAddIssue: onAddIssue,
				isInspectorVisible: $isInspectorVisible
			)
			IssueColumn(
				title: "Review",
				status: .review,
				issues: issuesByStatus[.review] ?? [],
				color: .purple,
				onAddIssue: onAddIssue,
				isInspectorVisible: $isInspectorVisible
			)
			IssueColumn(
				title: "Done",
				status: .done,
				issues: issuesByStatus[.done] ?? [],
				color: .green,
				onAddIssue: onAddIssue,
				isInspectorVisible: $isInspectorVisible
			)
		}
	}
}

// List View
struct IssueListView: View {
	let issuesByStatus: [IssueStatus: [Issue]]
	let onAddIssue: (IssueStatus) -> Void
	@Binding var isInspectorVisible: Bool

	private let statuses: [(status: IssueStatus, title: String, color: Color)] = [
		(.todo, "To Do", .gray),
		(.inProgress, "In Progress", .orange),
		(.review, "Review", .purple),
		(.done, "Done", .green)
	]

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {
				ForEach(statuses, id: \.status) { statusInfo in
					IssueSection(
						title: statusInfo.title,
						status: statusInfo.status,
						issues: issuesByStatus[statusInfo.status] ?? [],
						color: statusInfo.color,
						onAddIssue: onAddIssue,
						isInspectorVisible: $isInspectorVisible
					)
				}
			}
		}
	}
}

struct IssueSection: View {
	let title: String
	let status: IssueStatus
	let issues: [Issue]
	let color: Color
	let onAddIssue: (IssueStatus) -> Void
	@Binding var isInspectorVisible: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			// Section header
			HStack {
				HStack(spacing: 8) {
					Circle()
						.fill(color)
						.frame(width: 8, height: 8)

					Text(title)
						.font(.headline)
						.foregroundStyle(.primary)

					Text("\(issues.count)")
						.font(.caption)
						.foregroundStyle(.secondary)
						.padding(.horizontal, 6)
						.padding(.vertical, 2)
						.background(.tertiary.opacity(0.5))
						.clipShape(RoundedRectangle(cornerRadius: 4))
				}

				Spacer()

				Button(action: { onAddIssue(status) }) {
					Image(systemName: "plus.circle.fill")
						.foregroundStyle(color)
				}
				.buttonStyle(.plain)
			}

			// Issue cards
			VStack(spacing: 8) {
				ForEach(issues) { issue in
					IssueCard(issue: issue, isInspectorVisible: $isInspectorVisible)
				}

				if issues.isEmpty {
					Text("No issues")
						.font(.caption)
						.foregroundStyle(.secondary)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 24)
						.background(.bar.opacity(0.5))
						.clipShape(RoundedRectangle(cornerRadius: 8))
				}
			}
		}
	}
}

struct IssueColumn: View {
	let title: String
	let status: IssueStatus
	let issues: [Issue]
	let color: Color
	let onAddIssue: (IssueStatus) -> Void
	@Binding var isInspectorVisible: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			// Column header
			HStack {
				Text(title)
					.font(.headline)
					.foregroundStyle(.primary)

				Spacer()

				Text("\(issues.count)")
					.font(.caption)
					.foregroundStyle(.secondary)
					.padding(.horizontal, 6)
					.padding(.vertical, 2)
					.background(.tertiary.opacity(0.5))
					.clipShape(RoundedRectangle(cornerRadius: 4))
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.background(color.opacity(0.1))
			.clipShape(RoundedRectangle(cornerRadius: 8))

			// Issue cards
			ScrollView {
				VStack(spacing: 8) {
					ForEach(issues) { issue in
						IssueCard(issue: issue, isInspectorVisible: $isInspectorVisible)
					}

					// Add issue button
					Button(action: { onAddIssue(status) }) {
						HStack {
							Image(systemName: "plus.circle")
								.foregroundStyle(.secondary)

							Text("Add Issue")
								.font(.subheadline)
								.foregroundStyle(.secondary)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 12)
						.background(.bar.opacity(0.5))
						.clipShape(RoundedRectangle(cornerRadius: 8))
					}
					.buttonStyle(.plain)

					if issues.isEmpty {
						Text("No issues")
							.font(.caption)
							.foregroundStyle(.secondary)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 12)
					}
				}
			}
		}
		.frame(maxWidth: .infinity)
	}
}

struct IssueCard: View {
	let issue: Issue
	@Binding var isInspectorVisible: Bool
	@Environment(ProjectStore.self) private var projectStore

	private var priorityColor: Color {
		switch issue.priority {
		case .urgent: return .red
		case .high: return .orange
		case .medium: return .blue
		case .low: return .gray
		}
	}

	private var priorityIcon: String {
		switch issue.priority {
		case .urgent: return "exclamationmark.3"
		case .high: return "exclamationmark.2"
		case .medium: return "equal"
		case .low: return "minus"
		}
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			// Priority and title
			HStack(alignment: .top, spacing: 8) {
				Image(systemName: priorityIcon)
					.font(.caption2)
					.foregroundStyle(priorityColor)

				Text(issue.title)
					.font(.subheadline)
					.foregroundStyle(.primary)
					.lineLimit(2)

				Spacer()
			}

			// Due date if exists
			if let dueDate = issue.dueDate {
				HStack(spacing: 4) {
					Image(systemName: "calendar")
						.font(.caption2)
						.foregroundStyle(.secondary)

					Text(dueDate, style: .date)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}

			// Description if exists
			if let description = issue.issueDescription, !description.isEmpty {
				Text(description)
					.font(.caption)
					.foregroundStyle(.secondary)
					.lineLimit(2)
			}
		}
		.padding(12)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.bar)
		.clipShape(RoundedRectangle(cornerRadius: 8))
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(priorityColor.opacity(0.3), lineWidth: 1)
		)
		.onTapGesture {
			projectStore.selectedIssue = issue
			isInspectorVisible = true
		}
	}
}

struct ProjectUpdatesView: View {
	@Environment(ProjectStore.self) private var projectStore
	@Query private var allIssues: [Issue]

	private var projectIssues: [Issue] {
		guard let project = projectStore.selectedProject else { return [] }
		return allIssues.filter { $0.project?.id == project.id }
			.sorted { $0.updatedAt > $1.updatedAt }
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			if projectIssues.isEmpty {
				VStack(spacing: 12) {
					Image(systemName: "clock")
						.font(.system(size: 48))
						.foregroundStyle(.secondary)

					Text("No Recent Activity")
						.font(.headline)
						.foregroundStyle(.secondary)

					Text("Updates will appear here as issues are created and modified")
						.font(.caption)
						.foregroundStyle(.tertiary)
						.multilineTextAlignment(.center)
				}
				.frame(maxWidth: .infinity)
				.padding(.top, 60)
			} else {
				Text("Recent Activity")
					.font(.headline)

				VStack(alignment: .leading, spacing: 12) {
					ForEach(projectIssues.prefix(20)) { issue in
						UpdateItem(issue: issue)
					}
				}
			}

			Spacer()
		}
	}
}

struct UpdateItem: View {
	let issue: Issue

	private var statusColor: Color {
		switch issue.status {
		case .todo: return .gray
		case .inProgress: return .orange
		case .review: return .purple
		case .done: return .green
		}
	}

	private var statusIcon: String {
		switch issue.status {
		case .todo: return "circle"
		case .inProgress: return "arrow.right.circle.fill"
		case .review: return "eye.circle.fill"
		case .done: return "checkmark.circle.fill"
		}
	}

	private var timeAgo: String {
		let formatter = RelativeDateTimeFormatter()
		formatter.unitsStyle = .abbreviated
		return formatter.localizedString(for: issue.updatedAt, relativeTo: Date())
	}

	var body: some View {
		HStack(alignment: .top, spacing: 12) {
			// Status icon
			Image(systemName: statusIcon)
				.foregroundStyle(statusColor)
				.frame(width: 20)

			VStack(alignment: .leading, spacing: 4) {
				// Issue title
				Text(issue.title)
					.font(.subheadline)
					.foregroundStyle(.primary)

				// Status and time
				HStack(spacing: 8) {
					Text(issue.status.rawValue.capitalized)
						.font(.caption)
						.foregroundStyle(statusColor)

					Text("•")
						.foregroundStyle(.tertiary)

					Text(timeAgo)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}

			Spacer()

			// Priority indicator
			if issue.priority == .urgent || issue.priority == .high {
				Image(systemName: "exclamationmark.circle.fill")
					.font(.caption)
					.foregroundStyle(issue.priority == .urgent ? .red : .orange)
			}
		}
		.padding(12)
		.background(.bar)
		.clipShape(RoundedRectangle(cornerRadius: 8))
	}
}

// View Settings Popover
struct ViewSettingsPopover: View {
	@Environment(ProjectStore.self) private var projectStore
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("View Settings")
				.font(.headline)
				.padding(.horizontal)
				.padding(.top)

			Divider()

			// Only show view mode toggle for Issues view
			if case .project = projectStore.selectedView,
			   projectStore.selectedViewType == .issues {
				VStack(alignment: .leading, spacing: 8) {
					Text("Issues View Mode")
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.padding(.horizontal)

					Picker("View Mode", selection: Binding(
						get: { projectStore.issuesViewMode },
						set: { projectStore.issuesViewMode = $0 }
					)) {
						ForEach(IssuesViewMode.allCases, id: \.self) { mode in
							HStack {
								Image(systemName: mode == .board ? "square.grid.2x2" : "list.bullet")
								Text(mode.rawValue)
							}
							.tag(mode)
						}
					}
					.pickerStyle(.radioGroup)
					.padding(.horizontal)
				}

				Divider()
			}

			// Placeholder for future settings
			VStack(alignment: .leading, spacing: 8) {
				Text("More settings coming soon...")
					.font(.caption)
					.foregroundStyle(.tertiary)
					.padding(.horizontal)
			}

			Spacer()
		}
		.frame(width: 250, height: 200)
		.padding(.bottom)
	}
}

#Preview {
	DetailView(isInspectorVisible: .constant(false), isSidebarCollapsed: .constant(true))
		.environment(ProjectStore())
		.frame(width: 800, height: 600)
}
