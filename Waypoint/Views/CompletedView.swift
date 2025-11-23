//
//  CompletedView.swift
//  Waypoint
//

import SwiftUI
import SwiftData

struct CompletedView: View {
	@Binding var weekOffset: Int
	@Binding var isInspectorVisible: Bool
	@Environment(ViewSettingsStore.self) private var viewSettingsStore
	@Environment(ProjectStore.self) private var projectStore
	@Query private var allIssues: [Issue]
	@State private var showingCreateIssue = false
	@State private var createIssueDefaults: IssueDefaults?

	private var settings: ViewSettings {
		viewSettingsStore.completedSettings
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

	private var completedIssues: [Issue] {
		let calendar = Calendar.current
		let (weekStart, weekEnd) = weekDates

		return allIssues.filter { issue in
			guard let completedDate = issue.completedDate else { return false }
			let completedDateStart = calendar.startOfDay(for: completedDate)
			return completedDateStart >= weekStart && completedDateStart <= weekEnd
		}
	}

	private var sortedIssues: [Issue] {
		IssueSorter.sort(completedIssues, by: settings.sortBy, direction: settings.sortDirection)
	}

	private var groupedIssues: [IssueGroup] {
		let (weekStart, weekEnd) = weekDates
		return IssueGrouper.groupByCompletedWeekDays(sortedIssues, weekStart: weekStart, weekEnd: weekEnd)
	}

	var body: some View {
		Group {
				if completedIssues.isEmpty {
					emptyStateView
				} else {
					switch settings.viewMode {
					case .board:
						GenericIssueBoardView(
							groups: groupedIssues,
							grouping: .completedDate,
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
								grouping: .completedDate,
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
					defaultStatus: defaults.status ?? .done,
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
			Image(systemName: "checkmark.circle")
				.font(.system(size: 64))
				.foregroundStyle(.secondary)

			Text("No Completed Issues")
				.font(.title2)
				.fontWeight(.semibold)

			Text("No issues were completed this week")
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
				accentColor: projectStore.currentSpace.map { AppColor.color(from: $0.color) } ?? SystemView.completed.color
			)
			.padding(.top, 8)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(40)
	}
}

#Preview {
	CompletedView(weekOffset: .constant(0), isInspectorVisible: .constant(false))
		.environment(ViewSettingsStore())
		.modelContainer(for: [Issue.self, Project.self, Space.self, Tag.self])
}
