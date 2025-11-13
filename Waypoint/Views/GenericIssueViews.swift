//
//  GenericIssueViews.swift
//  Waypoint
//

import SwiftUI

// MARK: - Generic Board View

struct GenericIssueBoardView: View {
    let groups: [IssueGroup]
    let showAddButton: Bool
    let onAddIssue: ((IssueStatus?) -> Void)?
    @Binding var isInspectorVisible: Bool

    init(groups: [IssueGroup], showAddButton: Bool = true, onAddIssue: ((IssueStatus?) -> Void)? = nil, isInspectorVisible: Binding<Bool>) {
        self.groups = groups
        self.showAddButton = showAddButton
        self.onAddIssue = onAddIssue
        self._isInspectorVisible = isInspectorVisible
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(groups.sorted(by: { $0.order < $1.order })) { group in
                    GenericIssueColumn(
                        group: group,
                        showAddButton: showAddButton,
                        onAddIssue: onAddIssue,
                        isInspectorVisible: $isInspectorVisible
                    )
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Generic List View

struct GenericIssueListView: View {
    let groups: [IssueGroup]
    let showAddButton: Bool
    let onAddIssue: ((IssueStatus?) -> Void)?
    @Binding var isInspectorVisible: Bool

    init(groups: [IssueGroup], showAddButton: Bool = true, onAddIssue: ((IssueStatus?) -> Void)? = nil, isInspectorVisible: Binding<Bool>) {
        self.groups = groups
        self.showAddButton = showAddButton
        self.onAddIssue = onAddIssue
        self._isInspectorVisible = isInspectorVisible
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(groups.sorted(by: { $0.order < $1.order })) { group in
                GenericIssueSection(
                    group: group,
                    showAddButton: showAddButton,
                    onAddIssue: onAddIssue,
                    isInspectorVisible: $isInspectorVisible
                )
            }
        }
        .padding(20)
    }
}

// MARK: - Generic Issue Column (for Board)

struct GenericIssueColumn: View {
    let group: IssueGroup
    let showAddButton: Bool
    let onAddIssue: ((IssueStatus?) -> Void)?
    @Binding var isInspectorVisible: Bool

    private var color: Color {
        colorForGroup(group)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column header
            HStack {
                Text(group.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(group.issues.count)")
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
                    ForEach(group.issues) { issue in
                        IssueCard(issue: issue, isInspectorVisible: $isInspectorVisible)
                    }

                    // Add issue button (only for status-based grouping)
                    if showAddButton, let status = statusForGroup(group) {
                        Button(action: { onAddIssue?(status) }) {
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
                    }

                    if group.issues.isEmpty {
                        Text("No issues")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
        .frame(minWidth: 250, maxWidth: 400)
    }
}

// MARK: - Generic Issue Section (for List)

struct GenericIssueSection: View {
    let group: IssueGroup
    let showAddButton: Bool
    let onAddIssue: ((IssueStatus?) -> Void)?
    @Binding var isInspectorVisible: Bool

    private var color: Color {
        colorForGroup(group)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)

                    Text(group.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(group.issues.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tertiary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer()

                // Add button (only for status-based grouping)
                if showAddButton, let status = statusForGroup(group) {
                    Button(action: { onAddIssue?(status) }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(color)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Issue cards
            VStack(spacing: 8) {
                ForEach(group.issues) { issue in
                    IssueCard(issue: issue, isInspectorVisible: $isInspectorVisible)
                }

                if group.issues.isEmpty {
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

// MARK: - Helper Functions

private func colorForGroup(_ group: IssueGroup) -> Color {
    // Try to match status-based colors
    switch group.id {
    case "todo": return .gray
    case "inProgress": return .orange
    case "review": return .purple
    case "done": return .green
    case "urgent": return .red
    case "high": return .orange
    case "medium": return .blue
    case "low": return .gray
    case "overdue": return .red
    case "today": return .orange
    case "tomorrow": return .blue
    default: return .blue
    }
}

private func statusForGroup(_ group: IssueGroup) -> IssueStatus? {
    // Only return status if this is a status-based group
    switch group.id {
    case "todo": return .todo
    case "inProgress": return .inProgress
    case "review": return .review
    case "done": return .done
    default: return nil
    }
}
