//
//  UpcomingView.swift
//  Waypoint
//

import SwiftUI
import SwiftData

struct UpcomingView: View {
	@Binding var weekOffset: Int
	@Binding var isInspectorVisible: Bool
	@Environment(ViewSettingsStore.self) private var viewSettingsStore
	@Environment(ProjectStore.self) private var projectStore
	@Query private var allIssues: [Issue]
	@State private var showingCreateIssue = false
	@State private var createIssueDefaults: IssueDefaults?

	private var settings: ViewSettings {
		viewSettingsStore.upcomingSettings
	}

	private var weekDates: (start: Date, end: Date) {
		let calendar = Calendar.current
		let today = Date()

		// Get the start of the week for today
		guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today),
			  let offsetWeekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: weekInterval.start) else {
			return (today, today)
		}

		// Calculate end of week (6 days after start)
		guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: offsetWeekStart) else {
			return (offsetWeekStart, offsetWeekStart)
		}

		return (offsetWeekStart, weekEnd)
	}

	private var upcomingIssues: [Issue] {
		let calendar = Calendar.current
		let (weekStart, weekEnd) = weekDates

		return allIssues.filter { issue in
			guard let dueDate = issue.dueDate else { return false }
			let dueDateStart = calendar.startOfDay(for: dueDate)
			return dueDateStart >= weekStart && dueDateStart <= weekEnd
		}
	}

	private var sortedIssues: [Issue] {
		IssueSorter.sort(upcomingIssues, by: settings.sortBy, direction: settings.sortDirection)
	}

	private var groupedIssues: [IssueGroup] {
		let (weekStart, weekEnd) = weekDates
		return IssueGrouper.groupByWeekDays(sortedIssues, weekStart: weekStart, weekEnd: weekEnd)
	}

	var body: some View {
		Group {
				if upcomingIssues.isEmpty {
					emptyStateView
				} else {
					switch settings.viewMode {
					case .board:
						GenericIssueBoardView(
							groups: groupedIssues,
							grouping: .dueDate,
							showAddButton: true,
							onAddIssue: { defaults in
								createIssueDefaults = defaults
								showingCreateIssue = true
							},
							isInspectorVisible: $isInspectorVisible
						)
					case .list:
						ScrollView {
							GenericIssueListView(
								groups: groupedIssues,
								grouping: .dueDate,
								showAddButton: true,
								onAddIssue: { defaults in
									createIssueDefaults = defaults
									showingCreateIssue = true
								},
								isInspectorVisible: $isInspectorVisible
							)
					}
				}
			}
		}
		.sheet(isPresented: $showingCreateIssue) {
			if let defaults = createIssueDefaults {
				CreateIssueSheet(
					defaultStatus: defaults.status ?? .todo,
					defaultPriority: defaults.priority,
					defaultDueDate: defaults.dueDate,
					project: defaults.project,
					defaultTags: defaults.tags
				)
			} else {
				CreateIssueSheet(project: nil)
			}
		}
	}

	private var emptyStateView: some View {
		VStack(spacing: 16) {
			Image(systemName: "calendar.badge.clock")
				.font(.system(size: 64))
				.foregroundStyle(.secondary)

			Text("No Upcoming Issues")
				.font(.title2)
				.fontWeight(.semibold)

			Text("No issues are scheduled for this week")
				.font(.body)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)

			KeyboardShortcutButton(
				label: "Create Issue",
				action: { showingCreateIssue = true },
				icon: "plus",
				iconColor: .white,
				shortcutKey: "⇧N",
				tooltip: "Create new issue (⌘⇧N)",
				style: .primary,
				accentColor: projectStore.currentSpace.map { AppColor.color(from: $0.color) } ?? SystemView.upcoming.color
			)
			.padding(.top, 8)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(40)
	}
}

#Preview {
	UpcomingView(weekOffset: .constant(0), isInspectorVisible: .constant(false))
		.environment(ViewSettingsStore())
		.modelContainer(for: [Issue.self, Project.self, Space.self, Tag.self])
}
