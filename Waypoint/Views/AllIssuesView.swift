//
//  AllIssuesView.swift
//  Waypoint
//

import SwiftUI
import SwiftData

struct AllIssuesView: View {
    @Environment(ViewSettingsStore.self) private var viewSettingsStore
    @Query private var allIssues: [Issue]
    @State private var showingCreateIssue = false
    @State private var createIssueDefaults: IssueDefaults?
    @Binding var isInspectorVisible: Bool

    private var settings: ViewSettings {
        viewSettingsStore.allIssuesSettings
    }

    private var sortedIssues: [Issue] {
        IssueSorter.sort(allIssues, by: settings.sortBy, direction: settings.sortDirection)
    }

    private var groupedIssues: [IssueGroup] {
        IssueGrouper.group(sortedIssues, by: settings.groupBy)
    }

    var body: some View {
        Group {
            if allIssues.isEmpty {
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
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Issues")
                .font(.title2)
                .fontWeight(.semibold)

            Text("All your issues will appear here")
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
    AllIssuesView(isInspectorVisible: .constant(false))
        .environment(ViewSettingsStore())
        .modelContainer(for: [Issue.self, Project.self, Space.self, Tag.self])
}
