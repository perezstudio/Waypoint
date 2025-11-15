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
			case .allIssues: return "All Issues"
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
			// Show for inbox, today, upcoming, completed, and projects
			return true
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
			case .allIssues:
				return Binding(
					get: { viewSettingsStore.allIssuesSettings },
					set: { viewSettingsStore.updateSettings($0, for: .allIssues) }
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

	private var currentProjectViewSettings: Binding<ProjectViewSettings>? {
		switch projectStore.selectedView {
		case .system(let systemView):
			if systemView == .projects {
				return Binding(
					get: { viewSettingsStore.projectsSettings },
					set: { viewSettingsStore.projectsSettings = $0 }
				)
			}
			return nil
		case .project:
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
				// Left: Sidebar Toggle (when collapsed) + Back Button (if from projects list) + Icon + View Name
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

					// Back button - show when viewing project that came from projects list
					if case .project = projectStore.selectedView, projectStore.cameFromProjectsList {
						SidebarIconButton(
							icon: "chevron.left",
							action: {
								withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
									projectStore.selectSystemView(.projects)
								}
							},
							tooltip: "Back to Projects"
						)
						.transition(.asymmetric(
							insertion: .move(edge: .leading).combined(with: .opacity),
							removal: .move(edge: .leading).combined(with: .opacity)
						))
					}

					Image(systemName: viewIcon)
						.font(.title2)
						.foregroundStyle(viewColor)

					Text(viewName)
						.font(.title2)
						.fontWeight(.semibold)
				}
				.animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSidebarCollapsed)
				.animation(.spring(response: 0.3, dampingFraction: 0.8), value: projectStore.cameFromProjectsList)

				Spacer()

				// Middle: View Settings Controls (when applicable)
				if shouldShowViewSettingsToolbar, let projectSettings = currentProjectViewSettings {
					HStack(alignment: .center, spacing: 24) {
						// View mode picker
						VStack(alignment: .center, spacing: 4) {
							if viewSettingsStore.controlDisplayMode == .textOnly {
								Picker("", selection: Binding(
									get: { projectSettings.wrappedValue.viewMode },
									set: {
										var newSettings = projectSettings.wrappedValue
										newSettings.viewMode = $0
										projectSettings.wrappedValue = newSettings
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
									get: { projectSettings.wrappedValue.viewMode },
									set: {
										var newSettings = projectSettings.wrappedValue
										newSettings.viewMode = $0
										projectSettings.wrappedValue = newSettings
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

						// Group by menu (for projects)
						ViewControlMenu(
							icon: projectSettings.wrappedValue.groupBy.icon,
							text: "Group",
							selectedText: projectSettings.wrappedValue.groupBy.rawValue
						) {
							ForEach(ProjectGrouping.allCases, id: \.self) { grouping in
								Button(action: {
									var newSettings = projectSettings.wrappedValue
									newSettings.groupBy = grouping
									projectSettings.wrappedValue = newSettings
								}) {
									HStack {
										Image(systemName: grouping.icon)
										Text(grouping.rawValue)
										if projectSettings.wrappedValue.groupBy == grouping {
											Spacer()
											Image(systemName: "checkmark")
										}
									}
								}
							}
						}

						// Sort controls (for projects)
						VStack(alignment: .center, spacing: 4) {
							HStack(spacing: 6) {
								// Sort by menu
								ViewControlMenu(
									icon: projectSettings.wrappedValue.sortBy.icon,
									text: "Sort",
									selectedText: projectSettings.wrappedValue.sortBy.rawValue,
									showLabel: false
								) {
									ForEach(ProjectSorting.allCases, id: \.self) { sorting in
										Button(action: {
											var newSettings = projectSettings.wrappedValue
											newSettings.sortBy = sorting
											projectSettings.wrappedValue = newSettings
										}) {
											HStack {
												Image(systemName: sorting.icon)
												Text(sorting.rawValue)
												if projectSettings.wrappedValue.sortBy == sorting {
													Spacer()
													Image(systemName: "checkmark")
												}
											}
										}
									}
								}

								// Sort direction button
								ViewControlButton(
									icon: projectSettings.wrappedValue.sortDirection.icon,
									text: projectSettings.wrappedValue.sortDirection.rawValue,
									showLabel: false
								) {
									var newSettings = projectSettings.wrappedValue
									newSettings.sortDirection = newSettings.sortDirection == .ascending ? .descending : .ascending
									projectSettings.wrappedValue = newSettings
								}
							}

							if viewSettingsStore.controlDisplayMode != .iconOnly {
								Text("Sort")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
					}
				} else if shouldShowViewSettingsToolbar, let settings = currentViewSettings {
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
		case .allIssues:
			AllIssuesView(isInspectorVisible: $isInspectorVisible)
		case .today:
			TodayView(isInspectorVisible: $isInspectorVisible)
		case .upcoming:
			Text("Upcoming Tasks")
				.foregroundStyle(.secondary)
		case .completed:
			Text("Completed Tasks")
				.foregroundStyle(.secondary)
		case .projects:
			ProjectsListView()
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

// Project Overview View
struct ProjectOverviewView: View {
	@Environment(ProjectStore.self) private var projectStore
	@Environment(\.modelContext) private var modelContext

	@State private var showAddResource = false
	@State private var showAddUpdate = false
	@State private var showAddMilestone = false

	private var project: Project? {
		projectStore.selectedProject
	}

	private var statusText: String {
		guard let project = project else { return "" }
		switch project.status {
		case .todo: return "To Do"
		case .inProgress: return "In Progress"
		case .review: return "Review"
		case .done: return "Done"
		}
	}

	private var statusColor: Color {
		guard let project = project else { return .gray }
		switch project.status {
		case .todo: return .gray
		case .inProgress: return .orange
		case .review: return .purple
		case .done: return .green
		}
	}

	private var sortedResources: [Resource] {
		project?.resources.sorted { $0.createdAt > $1.createdAt } ?? []
	}

	private var latestUpdate: ProjectUpdate? {
		project?.updates.sorted { $0.createdAt > $1.createdAt }.first
	}

	private var sortedMilestones: [Milestone] {
		project?.milestones.sorted { $0.order < $1.order } ?? []
	}

	var body: some View {
		ScrollView {
			VStack(alignment: .center, spacing: 32) {
				// Project Header
				projectHeader

				// Main content container
				VStack(alignment: .leading, spacing: 24) {
					// Properties
					propertiesSection

					// Resources & Links
					resourcesSection

					// Latest Update
					updatesSection

					// Description Editor
					descriptionSection

					// Milestones
					milestonesSection
				}
				.frame(maxWidth: 800)
			}
			.frame(maxWidth: .infinity)
			.padding(32)
		}
		.sheet(isPresented: $showAddResource) {
			if let project = project {
				AddResourceSheet(project: project)
			}
		}
		.sheet(isPresented: $showAddUpdate) {
			if let project = project {
				AddUpdateSheet(project: project)
			}
		}
		.sheet(isPresented: $showAddMilestone) {
			if let project = project {
				AddMilestoneSheet(project: project)
			}
		}
	}

	private var projectHeader: some View {
		VStack(spacing: 16) {
			// Icon with colored background
			if let project = project {
				ZStack {
					Circle()
						.fill(AppColor.color(from: project.color).opacity(0.2))
						.frame(width: 80, height: 80)
					Image(systemName: project.icon)
						.font(.system(size: 40))
						.foregroundStyle(AppColor.color(from: project.color))
				}

				// Project name
				Text(project.name)
					.font(.largeTitle)
					.fontWeight(.bold)
			}
		}
	}

	private var propertiesSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			SectionHeader(title: "Properties")

			LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
				ProjectPropertyRow(label: "Status", value: statusText, color: statusColor)
				ProjectPropertyRow(label: "Space", value: project?.space?.name ?? "No Space")
				ProjectPropertyRow(label: "Created", value: project?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "")
				ProjectPropertyRow(label: "Updated", value: project?.updatedAt.formatted(date: .abbreviated, time: .omitted) ?? "")
				ProjectPropertyRow(label: "Issues", value: "\(project?.issues.count ?? 0)")
			}
		}
		.padding(20)
		.background(.bar)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}

	private var resourcesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			SectionHeader(title: "Resources & Links", action: { showAddResource = true })

			if sortedResources.isEmpty {
				EmptyStateView(
					icon: "link",
					title: "No resources yet",
					subtitle: "Add links and files to keep everything in one place"
				)
			} else {
				VStack(spacing: 8) {
					ForEach(sortedResources) { resource in
						ResourceRow(resource: resource)
					}
				}
			}
		}
		.padding(20)
		.background(.bar)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}

	private var updatesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			SectionHeader(title: "Latest Update", action: { showAddUpdate = true })

			if let update = latestUpdate {
				VStack(alignment: .leading, spacing: 8) {
					HStack {
						if let author = update.author, !author.isEmpty {
							Text(author)
								.font(.subheadline)
								.fontWeight(.semibold)
						}
						Spacer()
						Text(update.createdAt, style: .relative)
							.font(.caption)
							.foregroundStyle(.secondary)
					}

					Text(update.content)
						.font(.body)
						.lineLimit(5)

					if let project = project, project.updates.count > 1 {
						Button("View all updates (\(project.updates.count))") {
							// Navigate to updates tab
							projectStore.selectedViewType = .updates
						}
						.font(.caption)
						.foregroundStyle(.blue)
					}
				}
				.padding(16)
				.background(Color(nsColor: .controlBackgroundColor))
				.clipShape(RoundedRectangle(cornerRadius: 8))
			} else {
				EmptyStateView(
					icon: "megaphone",
					title: "No updates yet",
					subtitle: "Share progress and keep your team informed",
					buttonTitle: "Add First Update",
					buttonAction: { showAddUpdate = true }
				)
			}
		}
		.padding(20)
		.background(.bar)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}

	private var descriptionSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			SectionHeader(title: "Description")

			if let project = project {
				ProjectEditorView(project: project)
					.frame(maxWidth: .infinity, alignment: .topLeading)
			}
		}
		.padding(20)
		.background(.bar)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}

	private var milestonesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			SectionHeader(title: "Milestones", action: { showAddMilestone = true })

			if sortedMilestones.isEmpty {
				EmptyStateView(
					icon: "flag",
					title: "No milestones yet",
					subtitle: "Break your project into key milestones"
				)
			} else {
				VStack(spacing: 8) {
					ForEach(sortedMilestones) { milestone in
						MilestoneRow(milestone: milestone) { completed in
							toggleMilestone(milestone, completed: completed)
						}
					}
				}
			}
		}
		.padding(20)
		.background(.bar)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}

	private func toggleMilestone(_ milestone: Milestone, completed: Bool) {
		milestone.isCompleted = completed
		milestone.completedAt = completed ? Date() : nil
		try? modelContext.save()
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
	@State private var createIssueForStatus: Status?
	@Binding var isInspectorVisible: Bool

	private var projectIssues: [Issue] {
		guard let project = projectStore.selectedProject else { return [] }
		return allIssues.filter { $0.project?.id == project.id }
	}

	private var issuesByStatus: [Status: [Issue]] {
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
	let issuesByStatus: [Status: [Issue]]
	let onAddIssue: (Status) -> Void
	@Binding var isInspectorVisible: Bool
	@FocusState private var focusedElement: FocusableElement?

	var body: some View {
		HStack(alignment: .top, spacing: 16) {
			IssueColumn(
				title: "To Do",
				status: .todo,
				issues: issuesByStatus[.todo] ?? [],
				color: .gray,
				onAddIssue: onAddIssue,
				isInspectorVisible: $isInspectorVisible,
				focusedElement: $focusedElement
			)
			IssueColumn(
				title: "In Progress",
				status: .inProgress,
				issues: issuesByStatus[.inProgress] ?? [],
				color: .orange,
				onAddIssue: onAddIssue,
				isInspectorVisible: $isInspectorVisible,
				focusedElement: $focusedElement
			)
			IssueColumn(
				title: "Review",
				status: .review,
				issues: issuesByStatus[.review] ?? [],
				color: .purple,
				onAddIssue: onAddIssue,
				isInspectorVisible: $isInspectorVisible,
				focusedElement: $focusedElement
			)
			IssueColumn(
				title: "Done",
				status: .done,
				issues: issuesByStatus[.done] ?? [],
				color: .green,
				onAddIssue: onAddIssue,
				isInspectorVisible: $isInspectorVisible,
				focusedElement: $focusedElement
			)
		}
	}
}

// List View
struct IssueListView: View {
	let issuesByStatus: [Status: [Issue]]
	let onAddIssue: (Status) -> Void
	@Binding var isInspectorVisible: Bool
	@FocusState private var focusedElement: FocusableElement?

	private let statuses: [(status: Status, title: String, color: Color)] = [
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
						isInspectorVisible: $isInspectorVisible,
						focusedElement: $focusedElement
					)
				}
			}
		}
	}
}

struct IssueSection: View {
	let title: String
	let status: Status
	let issues: [Issue]
	let color: Color
	let onAddIssue: (Status) -> Void
	@Binding var isInspectorVisible: Bool
	@FocusState.Binding var focusedElement: FocusableElement?

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
					IssueCard(issue: issue, isInspectorVisible: $isInspectorVisible, focusedElement: $focusedElement)
				}

				if issues.isEmpty {
					Text("No issues")
						.font(.caption)
						.foregroundStyle(.secondary)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 24)
						.background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
						.clipShape(RoundedRectangle(cornerRadius: 8))
				}
			}
		}
	}
}

struct IssueColumn: View {
	let title: String
	let status: Status
	let issues: [Issue]
	let color: Color
	let onAddIssue: (Status) -> Void
	@Binding var isInspectorVisible: Bool
	@FocusState.Binding var focusedElement: FocusableElement?

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
						IssueCard(issue: issue, isInspectorVisible: $isInspectorVisible, focusedElement: $focusedElement)
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
						.background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
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
	@FocusState.Binding var focusedElement: FocusableElement?

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

	private var isFocused: Bool {
		if case .issue(let id) = focusedElement {
			return id == issue.id
		}
		return false
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
		.background(isFocused ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
		.clipShape(RoundedRectangle(cornerRadius: 8))
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(isFocused ? Color.accentColor : priorityColor.opacity(0.3), lineWidth: isFocused ? 2 : 1)
		)
		.focusable()
		.focused($focusedElement, equals: .issue(issue.id))
		.onTapGesture {
			projectStore.selectedIssue = issue
			isInspectorVisible = true
			focusedElement = .issue(issue.id)
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
