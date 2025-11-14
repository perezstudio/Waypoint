//
//  InboxView.swift
//  Waypoint
//

import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(ViewSettingsStore.self) private var viewSettingsStore
    @Query private var allIssues: [Issue]
    @State private var showingCreateIssue = false
    @State private var createIssueWithStatus: Status?
    @Binding var isInspectorVisible: Bool

    private var settings: ViewSettings {
        viewSettingsStore.inboxSettings
    }

    private var inboxIssues: [Issue] {
        allIssues.filter { $0.project == nil }
    }

    private var sortedIssues: [Issue] {
        IssueSorter.sort(inboxIssues, by: settings.sortBy, direction: settings.sortDirection)
    }

    private var groupedIssues: [IssueGroup] {
        IssueGrouper.group(sortedIssues, by: settings.groupBy)
    }

    var body: some View {
        Group {
            if inboxIssues.isEmpty {
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
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Inbox is Empty")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Issues without a project will appear here")
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
    InboxView(isInspectorVisible: .constant(false))
        .environment(ViewSettingsStore())
        .modelContainer(for: [Issue.self, Project.self, Space.self, Tag.self])
}
