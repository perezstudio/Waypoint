//
//  TodayView.swift
//  Waypoint
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(ViewSettingsStore.self) private var viewSettingsStore
    @Query private var allIssues: [Issue]
    @State private var showingCreateIssue = false
    @State private var createIssueWithStatus: Status?
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
                        showAddButton: settings.groupBy == .status,
                        onAddIssue: { status in
                            createIssueWithStatus = status
                            showingCreateIssue = true
                        },
                        isInspectorVisible: $isInspectorVisible
                    )
                case .list:
                    ScrollView {
                        GenericIssueListView(
                            groups: groupedIssues,
                            showAddButton: settings.groupBy == .status,
                            onAddIssue: { status in
                                createIssueWithStatus = status
                                showingCreateIssue = true
                            },
                            isInspectorVisible: $isInspectorVisible
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateIssue) {
            if let status = createIssueWithStatus {
                CreateIssueSheet(defaultStatus: status, project: nil)
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

            Button(action: { showingCreateIssue = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Issue")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
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
