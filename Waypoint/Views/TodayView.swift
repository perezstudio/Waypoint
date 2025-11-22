//
//  TodayView.swift
//  Waypoint
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(ViewSettingsStore.self) private var viewSettingsStore
    @Environment(ProjectStore.self) private var projectStore
    @Query private var allIssues: [Issue]
    @State private var showingCreateIssue = false
    @State private var createIssueDefaults: IssueDefaults?
    @Binding var isInspectorVisible: Bool

    private var settings: ViewSettings {
        viewSettingsStore.todaySettings
    }

    private var todayIssues: [Issue] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return allIssues.filter { issue in
            guard let dueDate = issue.dueDate else { return false }
            let dueDateStart = calendar.startOfDay(for: dueDate)
            return dueDateStart <= today // Due today or overdue
        }
    }

    private var sortedIssues: [Issue] {
        IssueSorter.sort(todayIssues, by: settings.sortBy, direction: settings.sortDirection)
    }

    private var groupedIssues: [IssueGroup] {
        IssueGrouper.group(sortedIssues, by: settings.groupBy)
    }

    var body: some View {
        Group {
            if todayIssues.isEmpty {
                emptyStateView
            } else {
                switch settings.viewMode {
                case .board:
                    GenericIssueBoardView(
                        groups: groupedIssues,
                        grouping: settings.groupBy,
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
                            grouping: settings.groupBy,
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
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("All Clear!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No issues are due today or overdue")
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
                accentColor: projectStore.currentSpace.map { AppColor.color(from: $0.color) } ?? SystemView.today.color
            )
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    TodayView(isInspectorVisible: .constant(false))
        .environment(ViewSettingsStore())
        .modelContainer(for: [Issue.self, Project.self, Space.self, Tag.self])
}
