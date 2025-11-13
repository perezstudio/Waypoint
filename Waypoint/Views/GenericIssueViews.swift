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
    @FocusState private var focusedElement: FocusableElement?
    @Environment(ProjectStore.self) private var projectStore

    init(groups: [IssueGroup], showAddButton: Bool = true, onAddIssue: ((IssueStatus?) -> Void)? = nil, isInspectorVisible: Binding<Bool>) {
        self.groups = groups
        self.showAddButton = showAddButton
        self.onAddIssue = onAddIssue
        self._isInspectorVisible = isInspectorVisible
    }

    // Build 2D grid structure: array of columns, each containing array of elements
    private var gridStructure: [[FocusableElement]] {
        var grid: [[FocusableElement]] = []
        for group in groups.sorted(by: { $0.order < $1.order }) {
            var column: [FocusableElement] = []
            // Add all issues
            for issue in group.issues {
                column.append(.issue(issue.id))
            }
            // Add the add button if applicable
            if showAddButton && statusForGroup(group) != nil {
                column.append(.addButton(group.id))
            }
            grid.append(column)
        }
        return grid
    }

    // Find current position in grid
    private func findPosition(of element: FocusableElement) -> (column: Int, row: Int)? {
        for (colIndex, column) in gridStructure.enumerated() {
            if let rowIndex = column.firstIndex(of: element) {
                return (colIndex, rowIndex)
            }
        }
        return nil
    }

    private func moveLeft() {
        guard let currentFocus = focusedElement,
              let position = findPosition(of: currentFocus),
              position.column > 0 else {
            // Focus first element in first column if nothing focused or at leftmost
            focusedElement = gridStructure.first?.first
            return
        }

        let targetColumn = position.column - 1
        let targetRow = min(position.row, gridStructure[targetColumn].count - 1)
        focusedElement = gridStructure[targetColumn][targetRow]
    }

    private func moveRight() {
        guard let currentFocus = focusedElement,
              let position = findPosition(of: currentFocus),
              position.column < gridStructure.count - 1 else {
            // Focus first element if nothing focused, stay at rightmost if at end
            if focusedElement == nil {
                focusedElement = gridStructure.first?.first
            }
            return
        }

        let targetColumn = position.column + 1
        let targetRow = min(position.row, gridStructure[targetColumn].count - 1)
        focusedElement = gridStructure[targetColumn][targetRow]
    }

    private func moveUp() {
        guard let currentFocus = focusedElement,
              let position = findPosition(of: currentFocus),
              position.row > 0 else {
            // Focus first element in first column if nothing focused or at top
            focusedElement = gridStructure.first?.first
            return
        }

        focusedElement = gridStructure[position.column][position.row - 1]
    }

    private func moveDown() {
        guard let currentFocus = focusedElement,
              let position = findPosition(of: currentFocus) else {
            // Focus first element if nothing focused
            focusedElement = gridStructure.first?.first
            return
        }

        let column = gridStructure[position.column]
        guard position.row < column.count - 1 else {
            // At bottom, stay there
            return
        }

        focusedElement = column[position.row + 1]
    }

    private func activateFocused() {
        guard let focused = focusedElement else { return }

        switch focused {
        case .issue(let issueId):
            // Find and select the issue
            for group in groups {
                if let issue = group.issues.first(where: { $0.id == issueId }) {
                    projectStore.selectedIssue = issue
                    isInspectorVisible = true
                    return
                }
            }
        case .addButton(let groupId):
            // Trigger add issue for this group
            if let group = groups.first(where: { $0.id == groupId }),
               let status = statusForGroup(group) {
                onAddIssue?(status)
            }
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(groups.sorted(by: { $0.order < $1.order })) { group in
                    GenericIssueColumn(
                        group: group,
                        showAddButton: showAddButton,
                        onAddIssue: onAddIssue,
                        isInspectorVisible: $isInspectorVisible,
                        focusedElement: $focusedElement
                    )
                }
            }
            .padding(20)
        }
        .onKeyPress(.upArrow) {
            moveUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveDown()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            moveLeft()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            moveRight()
            return .handled
        }
        .onKeyPress(.return) {
            activateFocused()
            return .handled
        }
        .onKeyPress(.escape) {
            focusedElement = nil
            return .handled
        }
    }
}

// MARK: - Generic List View

struct GenericIssueListView: View {
    let groups: [IssueGroup]
    let showAddButton: Bool
    let onAddIssue: ((IssueStatus?) -> Void)?
    @Binding var isInspectorVisible: Bool
    @FocusState private var focusedElement: FocusableElement?
    @Environment(ProjectStore.self) private var projectStore

    init(groups: [IssueGroup], showAddButton: Bool = true, onAddIssue: ((IssueStatus?) -> Void)? = nil, isInspectorVisible: Binding<Bool>) {
        self.groups = groups
        self.showAddButton = showAddButton
        self.onAddIssue = onAddIssue
        self._isInspectorVisible = isInspectorVisible
    }

    // Build flat list of all focusable elements in order
    private var focusableElements: [FocusableElement] {
        var elements: [FocusableElement] = []
        for group in groups.sorted(by: { $0.order < $1.order }) {
            // Add all issues in this group
            for issue in group.issues {
                elements.append(.issue(issue.id))
            }
            // Add the add button for this group if applicable
            if showAddButton && statusForGroup(group) != nil {
                elements.append(.addButton(group.id))
            }
        }
        return elements
    }

    private func moveUp() {
        guard let currentFocus = focusedElement,
              let currentIndex = focusableElements.firstIndex(of: currentFocus),
              currentIndex > 0 else {
            // Focus first element if nothing focused or at top
            focusedElement = focusableElements.first
            return
        }
        focusedElement = focusableElements[currentIndex - 1]
    }

    private func moveDown() {
        guard let currentFocus = focusedElement,
              let currentIndex = focusableElements.firstIndex(of: currentFocus),
              currentIndex < focusableElements.count - 1 else {
            // Focus first element if nothing focused, stay at bottom if at end
            if focusedElement == nil {
                focusedElement = focusableElements.first
            }
            return
        }
        focusedElement = focusableElements[currentIndex + 1]
    }

    private func activateFocused() {
        guard let focused = focusedElement else { return }

        switch focused {
        case .issue(let issueId):
            // Find and select the issue
            for group in groups {
                if let issue = group.issues.first(where: { $0.id == issueId }) {
                    projectStore.selectedIssue = issue
                    isInspectorVisible = true
                    return
                }
            }
        case .addButton(let groupId):
            // Trigger add issue for this group
            if let group = groups.first(where: { $0.id == groupId }),
               let status = statusForGroup(group) {
                onAddIssue?(status)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(groups.sorted(by: { $0.order < $1.order })) { group in
                GenericIssueSection(
                    group: group,
                    showAddButton: showAddButton,
                    onAddIssue: onAddIssue,
                    isInspectorVisible: $isInspectorVisible,
                    focusedElement: $focusedElement
                )
            }
        }
        .padding(20)
        .onKeyPress(.upArrow) {
            moveUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveDown()
            return .handled
        }
        .onKeyPress(.return) {
            activateFocused()
            return .handled
        }
        .onKeyPress(.escape) {
            focusedElement = nil
            return .handled
        }
    }
}

// MARK: - Generic Issue Column (for Board)

struct GenericIssueColumn: View {
    let group: IssueGroup
    let showAddButton: Bool
    let onAddIssue: ((IssueStatus?) -> Void)?
    @Binding var isInspectorVisible: Bool
    @FocusState.Binding var focusedElement: FocusableElement?

    private var color: Color {
        colorForGroup(group)
    }

    private var isAddButtonFocused: Bool {
        if case .addButton(let id) = focusedElement {
            return id == group.id
        }
        return false
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
                        IssueCard(
                            issue: issue,
                            isInspectorVisible: $isInspectorVisible,
                            focusedElement: $focusedElement
                        )
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
                            .background(isAddButtonFocused ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isAddButtonFocused ? Color.accentColor : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                        .focusable()
                        .focused($focusedElement, equals: .addButton(group.id))
                        .onTapGesture {
                            focusedElement = .addButton(group.id)
                        }
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
    @FocusState.Binding var focusedElement: FocusableElement?

    private var color: Color {
        colorForGroup(group)
    }

    private var isAddButtonFocused: Bool {
        if case .addButton(let id) = focusedElement {
            return id == group.id
        }
        return false
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
                    .padding(4)
                    .background(isAddButtonFocused ? Color.accentColor.opacity(0.1) : .clear)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isAddButtonFocused ? Color.accentColor : .clear, lineWidth: 2)
                    )
                    .focusable()
                    .focused($focusedElement, equals: .addButton(group.id))
                    .onTapGesture {
                        focusedElement = .addButton(group.id)
                    }
                }
            }

            // Issue cards
            VStack(spacing: 8) {
                ForEach(group.issues) { issue in
                    IssueCard(
                        issue: issue,
                        isInspectorVisible: $isInspectorVisible,
                        focusedElement: $focusedElement
                    )
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
